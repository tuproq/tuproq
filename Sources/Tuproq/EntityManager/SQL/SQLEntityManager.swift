import Foundation

final class SQLEntityManager: EntityManager {
    private typealias ChangeSet = [String: (Codable?, Codable?)] // [property: (oldValue, newValue)]
    private typealias EntityChanges = [String: EntityMap]
    private typealias EntityChangeSets = [ObjectIdentifier: ChangeSet]
    private typealias EntityMap = [ObjectIdentifier: any Entity]
    private typealias EntityStates = [ObjectIdentifier: EntityState]

    let connectionPool: ConnectionPool
    let configuration: Configuration

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private var allQueries = [any Query]()
    private var entityInsertions = EntityMap()
    private var entityUpdates = EntityMap()
    private var entityDeletions = EntityMap()
    private var entityStates = EntityStates()
    private var entityChangeSets = EntityChangeSets()
    private var identityMap = EntityChanges()
    private var entityIdentifiers = [ObjectIdentifier: AnyHashable]()
    private var objectIdentifiers = [AnyHashable: ObjectIdentifier]()

    init(
        connectionPool: ConnectionPool,
        configuration: Configuration
    ) {
        self.connectionPool = connectionPool
        self.configuration = configuration

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.userInfo = [.entityManager: self]
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
    func propertyValueChanged<E: Entity>(
        _ entity: E,
        name: String,
        oldValue: Codable?,
        newValue: Codable?
    ) {
        let entityName = Configuration.entityName(from: entity)
        let objectID = ObjectIdentifier(entity)
        guard identityMap[entityName]?[objectID] != nil else { return }
        entityUpdates[objectID] = entity
        var changeSet = entityChangeSets[objectID, default: .init()]
        changeSet[name] = (oldValue, newValue)
        entityChangeSets[objectID] = changeSet
    }
}

extension SQLEntityManager {
    func createQueryBuilder() -> SQLQueryBuilder {
        .init()
    }

    func find<E: Entity>(_ entityType: E.Type, id: E.ID) async throws -> E? {
        let mapping = try mapping(from: entityType)
        let idColumn = idColumn(tableName: mapping.table)
        guard !(id as AnyObject is NSNull) else { return nil }
        let entityName = Configuration.entityName(from: entityType)

        if let objectID = objectIdentifiers[id], let entity = identityMap[entityName]?[objectID] as? E {
            return entity
        }

        let query = createQueryBuilder()
            .select()
            .from(mapping.table)
            .where("\(idColumn) = $1")
            .getQuery()

        if let entity: E = try await self.query(query.raw, arguments: [id]).first {
            let objectID = ObjectIdentifier(entity)
            addEntityToIdentityMap(entity)
            entityStates[objectID] = .managed

            return entity
        }

        return nil
    }

    @discardableResult
    func query<E: Entity>(_ string: String, arguments: [Codable?]) async throws -> [E] {
        let result = try await query(string, arguments: arguments)
        let data = try JSONSerialization.data(withJSONObject: result)
        let entities = try decoder.decode([E].self, from: data)

        for entity in entities {
            let objectID = ObjectIdentifier(entity)
            addEntityToIdentityMap(entity)
            entityStates[objectID] = .managed
        }

        return entities
    }

    @discardableResult
    func query(_ string: String, arguments: [Codable?]) async throws -> [[String: Any?]] {
        let connection = try await connectionPool.leaseConnection(timeout: .seconds(3))
        let result = try await connection.query(string, arguments: arguments)
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

            let columns = result.columns.map { ObjectHydration.Column($0.name, table: tables[$0.tableID]!) }
            let rootTable = columns.map { $0.table }.first! // TODO: fix identifying root table

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
    func persist<E: Entity>(_ entity: inout E) throws {
        var entityMap = EntityMap()
        try persist(&entity, visited: &entityMap)
    }

    private func persist<E: Entity>(_ entity: inout E, visited entityMap: inout EntityMap) throws {
        try mapping(from: E.self)
        let objectID = ObjectIdentifier(entity)
        guard entityMap[objectID] == nil else { return }

        if let state = entityStates[objectID] {
            if state == .removed {
                entityDeletions.removeValue(forKey: objectID)
                entityStates[objectID] = .managed
                entityMap[objectID] = entity
            }
        } else {
            try register(&entity)
            let objectID = ObjectIdentifier(entity)
            addEntityToIdentityMap(entity)
            entityStates[objectID] = .new
            entityInsertions[objectID] = entity
            entityMap[objectID] = entity
        }
    }

    private func register<E: Entity>(_ entity: inout E) throws {
        let dictionary = try encodeToDictionary(entity)
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        entity = try decoder.decode(E.self, from: data)
    }
}

extension SQLEntityManager {
    func remove<E: Entity>(_ entity: E) throws {
        var entityMap = EntityMap()
        try remove(entity, visited: &entityMap)
    }

    private func remove<E: Entity>(_ entity: E, visited entityMap: inout EntityMap) throws {
        try mapping(from: E.self)
        let objectID = ObjectIdentifier(entity)
        guard entityMap[objectID] == nil else { return }
        entityMap[objectID] = entity

        if let state = entityStates[objectID] {
            switch state {
            case .managed:
                entityDeletions[objectID] = entity
                entityStates[objectID] = .removed
            case .new: removeEntityFromIdentityMap(entity)
            default: break
            }
        }
    }
}

extension SQLEntityManager {
    private func addEntityToIdentityMap<E: Entity>(_ entity: E) {
        let entityName = Configuration.entityName(from: entity)
        let objectID = ObjectIdentifier(entity)
        identityMap[entityName, default: .init()][objectID] = entity
        entityIdentifiers[objectID] = entity.id
        objectIdentifiers[entity.id] = objectID
    }

    private func removeEntityFromIdentityMap<E: Entity>(_ entity: E) {
        let objectID = ObjectIdentifier(entity)

        if let id = entityIdentifiers[objectID] {
            objectIdentifiers.removeValue(forKey: id)
        }

        entityIdentifiers.removeValue(forKey: objectID)
        entityInsertions.removeValue(forKey: objectID)
        entityUpdates.removeValue(forKey: objectID)
        entityDeletions.removeValue(forKey: objectID)
        entityChangeSets.removeValue(forKey: objectID)
        entityStates.removeValue(forKey: objectID)

        let entityName = Configuration.entityName(from: entity)
        identityMap[entityName]?.removeValue(forKey: objectID)

        if let entityMap = identityMap[entityName], entityMap.isEmpty {
            identityMap.removeValue(forKey: entityName)
        }
    }
}

extension SQLEntityManager {
    func flush() async throws {
        do {
            let commitOrder = try getCommitOrder()

            for entityName in commitOrder {
                try prepareInserts(for: entityName)
            }

            for entityName in commitOrder {
                try prepareUpdates(for: entityName)
            }

            for entityName in commitOrder {
                try prepareDeletions(for: entityName)
            }

            if !allQueries.isEmpty {
                var postInserts = [[String: Any?]]()
                let connection = try await connectionPool.leaseConnection(timeout: .seconds(3))
                try await connection.beginTransaction()

                do {
                    for query in allQueries {
                        if let dictionary = try await self.query(query.raw).first {
                            postInserts.append(dictionary)
                        }
                    }

                    try await connection.commitTransaction()
                    connectionPool.returnConnection(connection)
                    cleanUpDirty()
                } catch {
                    allQueries.removeAll()
                    try await connection.rollbackTransaction()
                    connectionPool.returnConnection(connection)
                    throw error
                }
            }
        } catch {
            allQueries.removeAll()
            throw error
        }
    }

    private func getCommitOrder() throws -> [String] {
        let calculator = CommitOrderCalculator()
        var entityNames = [String]()

        func processEntityMap(_ entityMap: EntityMap) {
            for entity in entityMap.values {
                let entityName = Configuration.entityName(from: entity)
                let node = CommitOrderCalculator.Node(value: entityName)

                if !calculator.hasNode(node) {
                    calculator.addNode(node)
                    entityNames.append(entityName)
                }
            }
        }

        processEntityMap(entityInsertions)
        processEntityMap(entityUpdates)
        processEntityMap(entityDeletions)

        while !entityNames.isEmpty {
            let entityName = entityNames.removeFirst()
            let mapping = try mapping(from: entityName)

            for parentMapping in mapping.parents {
                let parentEntityName = Configuration.entityName(from: parentMapping.entity)
                let node = CommitOrderCalculator.Node(value: parentEntityName)

                if !calculator.hasNode(node) {
                    calculator.addNode(node)
                    entityNames.append(parentEntityName)
                }

                let dependency = CommitOrderCalculator.Dependency(
                    from: parentEntityName,
                    to: entityName,
                    weight: parentMapping.column.isNullable ? 0 : 1
                )
                calculator.addDependency(dependency)
            }
        }

        return calculator.sort()
    }

    private func cleanUpDirty() {
        for objectID in entityInsertions.keys {
            entityStates[objectID] = .managed
        }

        for entity in entityDeletions.values {
            removeEntityFromIdentityMap(entity)
        }

        entityInsertions.removeAll()
        entityUpdates.removeAll()
        entityDeletions.removeAll()
        entityChangeSets.removeAll()
        allQueries.removeAll()
    }

    private func prepareInserts(for entityName: String) throws {
        let mapping = try mapping(from: entityName)
        let idField = configuration.mapping(tableName: mapping.table)?.id.name ?? Configuration.defaultIDField

        for entity in entityInsertions.values {
            if entityName == Configuration.entityName(from: entity) {
                var columns = [String]()
                var values = [Any?]()

                for (field, value) in try encodeToDictionary(entity) {
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
                    .insert(into: mapping.table, columns: columns, values: values)
                    .returning()
                    .getQuery()
                allQueries.append(query)
            }
        }
    }

    private func prepareUpdates(for entityName: String) throws {
        let mapping = try mapping(from: entityName)
        let idColumn = idColumn(tableName: mapping.table)

        for (objectID, entity) in entityUpdates {
            if let id = entityIdentifiers[objectID], entityName == Configuration.entityName(from: entity) {
                var values = [(String, Any?)]()

                if let changeSet = entityChangeSets[objectID] {
                    for (key, (_, newValue)) in changeSet {
                        if let column = mapping.fields.first(where: { $0.name == key })?.column.name {
                            values.append((column, try encodeValue(newValue)))
                        } else if let column = mapping.parents.first(where: { $0.name == key })?.column.name,
                                  let entity = newValue as? (any Entity) {
                            values.append((column, try encodeValue(entity.id)))
                        }
                    }

                    let query = createQueryBuilder()
                        .update(table: mapping.table, values: values)
                        .where("\(idColumn) = '\(id)'") // TODO: provide id as arguments to query() method
                        .returning()
                        .getQuery()
                    allQueries.append(query)
                }
            }
        }
    }

    private func prepareDeletions(for entityName: String) throws {
        let table = try mapping(from: entityName).table
        let idColumn = idColumn(tableName: table)

        for objectID in entityDeletions.keys {
            if let id = entityIdentifiers[objectID] {
                let query = createQueryBuilder()
                    .delete()
                    .from(table)
                    .where("\(idColumn) = '\(id)'") // TODO: provide id as arguments to query() method
                    .returning()
                    .getQuery()
                allQueries.append(query)
            }
        }
    }

    private func idColumn(tableName: String) -> String {
        configuration.mapping(tableName: tableName)?.id.column ?? Configuration.defaultIDField
    }

    private func encodeToDictionary<E: Entity>(_ entity: E) throws -> [String: Any?] {
        guard let dictionary = try JSONSerialization.jsonObject(
            with: try encoder.encode(entity),
            options: .fragmentsAllowed
        ) as? [String: Any?] else { throw error(.entityToDictionaryFailed) }
        return dictionary
    }

    private func encodeValue(_ value: (any Codable)?) throws -> Any? {
        guard let value else { return nil }
        return try JSONSerialization.jsonObject(
            with: try encoder.encode(value),
            options: .fragmentsAllowed
        )
    }
}
