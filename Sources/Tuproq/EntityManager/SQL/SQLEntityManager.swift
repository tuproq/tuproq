import Foundation

final class SQLEntityManager: EntityManager {
    let connectionPool: ConnectionPool
    let configuration: Configuration
    private let changeTracker = EntityChangeTracker()

    init(
        connectionPool: ConnectionPool,
        configuration: Configuration
    ) {
        self.connectionPool = connectionPool
        self.configuration = configuration
    }
}

extension SQLEntityManager {
    func persist<E: Entity>(_ entity: inout E) throws {
        try mapping(from: E.self)
        try changeTracker.insert(&entity)
    }

    func remove<E: Entity>(_ entity: E) throws {
        try mapping(from: E.self)
        changeTracker.remove(entity)
    }

    func flush() async throws {
        do {
            let commitOrder = try await getCommitOrder()
            var queries = [SQLQuery]()

            for entityName in commitOrder {
                queries.append(contentsOf: try prepareInserts(for: entityName))
            }

            for entityName in commitOrder {
                queries.append(contentsOf: try prepareUpdates(for: entityName))
            }

            for entityName in commitOrder {
                queries.append(contentsOf: try prepareDeletions(for: entityName))
            }

            if !queries.isEmpty {
                var postInserts = [[String: Any?]]()
                let connection = try await connectionPool.leaseConnection(timeout: .seconds(3))
                try await connection.beginTransaction()

                do {
                    for query in queries {
                        if let dictionary = try await self.query(query.raw).first {
                            postInserts.append(dictionary)
                        }
                    }

                    try await connection.commitTransaction()
                    connectionPool.returnConnection(connection)
                    changeTracker.cleanUpDirty()
                } catch {
                    try await connection.rollbackTransaction()
                    connectionPool.returnConnection(connection)
                    throw error
                }
            }
        } catch {
            throw error
        }
    }
}

extension SQLEntityManager {
    func createQueryBuilder() -> SQLQueryBuilder {
        .init()
    }

    func find<E: Entity>(
        _ entityType: E.Type,
        id: E.ID
    ) async throws -> E? {
        let mapping = try mapping(from: entityType)
        let idColumn = idColumn(tableName: mapping.table)
        guard !(id as AnyObject is NSNull) else { return nil }

        if let entity = changeTracker.getEntityFromIdentityMap(entityType, id: id) {
            return entity
        }

        let query = createQueryBuilder()
            .select()
            .from(mapping.table)
            .where("\(idColumn) = $1")
            .getQuery()

        if let entity: E = try await self.query(query.raw, arguments: [id]).first {
            let objectID = ObjectIdentifier(entity)
            changeTracker.addEntityToIdentityMap(entity)
            changeTracker.setState(
                .managed,
                for: objectID
            )

            return entity
        }

        return nil
    }

    @discardableResult
    func query<E: Entity>(
        _ string: String,
        arguments: [Codable?]
    ) async throws -> [E] {
        let result = try await query(
            string,
            arguments: arguments
        )
        let data = try JSONSerialization.data(withJSONObject: result)
        let entities = try changeTracker.decoder.decode([E].self, from: data)

        for entity in entities {
            let objectID = ObjectIdentifier(entity)
            changeTracker.addEntityToIdentityMap(entity)
            changeTracker.setState(
                .managed,
                for: objectID
            )
        }

        return entities
    }

    @discardableResult
    func query(
        _ string: String,
        arguments: [Codable?]
    ) async throws -> [[String: Any?]] {
        let connection = try await connectionPool.leaseConnection(timeout: .seconds(3))
        let result = try await connection.query(
            string,
            arguments: arguments
        )
        connectionPool.returnConnection(connection)

        if let result {
            let tableIDs = Set<Int32>(result.columns.map { $0.tableID })
            let tables = try await fetchTables(tableIDs: tableIDs)

            if tables.isEmpty || result.columns.contains(where: { tables[$0.tableID] == nil }) {
                var array = [[String: Any?]]()

                for row in await result.rows {
                    var dictionary = [String: Any?]()

                    for (index, column) in result.columns.enumerated() {
                        dictionary[column.name] = row[index]
                    }

                    array.append(dictionary)
                }

                return array
            }

            let columns = result.columns.map {
                ObjectHydration.Column(
                    $0.name,
                    table: tables[$0.tableID, default: ""]
                )
            }
            let rootTable = columns.map { $0.table }.first ?? "" // TODO: fix identifying root table

            return await ObjectHydration(
                entityManager: self,
                result: .init(
                    columns: columns,
                    rows: result.rows
                ),
                rootTable: rootTable,
                tables: Set(tables.values)
            ).hydrate()
        }

        return .init()
    }

    // TODO: PostgreSQL specific
    private func fetchTables(tableIDs: Set<Int32>) async throws -> [Int32: String] {
        let string = "SELECT oid, relname FROM pg_class WHERE oid = ANY($1)"
        var dictionary = [Int32: String]()
        let connection = try await connectionPool.leaseConnection(timeout: .seconds(3))
        let result = try await connection.query(string, arguments: [Array(tableIDs)])
        connectionPool.returnConnection(connection)

        if let result {
            for row in await result.rows {
                if let oid = row[0] as? Int32, let table = row[1] as? String {
                    dictionary[oid] = table
                }
            }
        }

        return dictionary
    }
}

extension SQLEntityManager {
    @discardableResult
    private func mapping(from entityName: String) throws -> any EntityMapping {
        guard let mapping = configuration.mapping(entityName: entityName) else {
            throw TuproqError("Entity named \"\(entityName)\" is not registered.")
        }
        return mapping
    }

    @discardableResult
    private func mapping<E: Entity>(from entityType: E.Type) throws -> any EntityMapping {
        guard let mapping = configuration.mapping(from: entityType) else {
            throw TuproqError("Entity named \"\(entityType)\" is not registered.")
        }
        return mapping
    }
}

extension SQLEntityManager {
    private func getCommitOrder() async throws -> [String] {
        let calculator = CommitOrderCalculator()
        var entityNames = [String]()

        func processEntityMap(_ entityMap: EntityChangeTracker.EntityMap) async {
            for entity in entityMap.values {
                let entityName = Configuration.entityName(from: entity)
                let node = CommitOrderCalculator.Node(value: entityName)

                if !(await calculator.hasNode(node)) {
                    await calculator.addNode(node)
                    entityNames.append(entityName)
                }
            }
        }

        await processEntityMap(changeTracker.getInsertions())
        await processEntityMap(changeTracker.getUpdates())
        await processEntityMap(changeTracker.getRemovals())

        while !entityNames.isEmpty {
            let entityName = entityNames.removeFirst()
            let mapping = try mapping(from: entityName)

            for parentMapping in mapping.parents {
                let parentEntityName = Configuration.entityName(from: parentMapping.entity)
                let node = CommitOrderCalculator.Node(value: parentEntityName)

                if !(await calculator.hasNode(node)) {
                    await calculator.addNode(node)
                    entityNames.append(parentEntityName)
                }

                let dependency = CommitOrderCalculator.Dependency(
                    from: parentEntityName,
                    to: entityName,
                    weight: parentMapping.column.isNullable ? 0 : 1
                )
                await calculator.addDependency(dependency)
            }
        }

        return await calculator.sort()
    }

    private func prepareInserts(for entityName: String) throws -> [SQLQuery] {
        let mapping = try mapping(from: entityName)
        let idField = configuration.mapping(tableName: mapping.table)?.id.name ?? Configuration.defaultIDField
        var queries = [SQLQuery]()

        for entity in changeTracker.getInsertions().values {
            if entityName == Configuration.entityName(from: entity) {
                var columns = [String]()
                var values = [Any?]()

                for (field, value) in try changeTracker.encodeToDictionary(entity) {
                    if mapping.children.contains(where: { $0.name == field }) ||
                        mapping.siblings.contains(where: { $0.name == field }) {
                        continue
                    }

                    if mapping.parents.contains(where: { $0.name == field }) {
                        let column = Configuration.namingStrategy.joinColumn(field: field)
                        columns.append(column)

                        if let value,
                           let valueDictionary = value as? [String: Any?],
                           let id = valueDictionary[idField] {
                            values.append(id)
                        } else {
                            values.append(nil)
                        }
                    } else {
                        let column = Configuration.namingStrategy.column(field: field)
                        columns.append(column)
                        values.append(value)
                    }
                }

                let query = createQueryBuilder()
                    .insert(
                        into: mapping.table,
                        columns: columns,
                        values: values
                    )
                    .returning()
                    .getQuery()
                queries.append(query)
            }
        }

        return queries
    }

    private func prepareUpdates(for entityName: String) throws -> [SQLQuery] {
        let mapping = try mapping(from: entityName)
        let idColumn = idColumn(tableName: mapping.table)
        var queries = [SQLQuery]()

        for (objectID, entity) in changeTracker.getUpdates() {
            if let id = changeTracker.getID(for: objectID),
               entityName == Configuration.entityName(from: entity) {
                var values = [(String, Any?)]()

                if let changeSet = changeTracker.getChangeSet(for: objectID) {
                    for (key, (_, newValue)) in changeSet {
                        if let column = mapping.fields.first(where: { $0.name == key })?.column.name {
                            values.append((column, try changeTracker.encodeValue(newValue)))
                        } else if let column = mapping.parents.first(where: { $0.name == key })?.column.name,
                                  let entity = newValue as? (any Entity) {
                            values.append((column, try changeTracker.encodeValue(entity.id)))
                        }
                    }

                    let query = createQueryBuilder()
                        .update(
                            table: mapping.table,
                            values: values
                        )
                        .where("\(idColumn) = '\(id)'") // TODO: provide id as arguments to query() method
                        .returning()
                        .getQuery()
                    queries.append(query)
                }
            }
        }

        return queries
    }

    private func prepareDeletions(for entityName: String) throws -> [SQLQuery] {
        var queries = [SQLQuery]()
        let table = try mapping(from: entityName).table
        let idColumn = idColumn(tableName: table)

        for objectID in changeTracker.getRemovals().keys {
            if let id = changeTracker.getID(for: objectID) {
                let query = createQueryBuilder()
                    .delete()
                    .from(table)
                    .where("\(idColumn) = '\(id)'") // TODO: provide id as arguments to query() method
                    .returning()
                    .getQuery()
                queries.append(query)
            }
        }

        return queries
    }

    private func idColumn(tableName: String) -> String {
        configuration.mapping(tableName: tableName)?.id.column ?? Configuration.defaultIDField
    }
}
