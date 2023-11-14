import Foundation

final class SQLEntityManager<QB: SQLQueryBuilder>: EntityManager {
    private typealias ChangeSet = [String: (Codable?, Codable?)] // [property: (oldValue, newValue)]
    private typealias EntityChanges = [String: EntityMap]
    private typealias EntityChangeSets = [ObjectIdentifier: ChangeSet]
    private typealias EntityMap = [ObjectIdentifier: any Entity]
    private typealias EntityStates = [ObjectIdentifier: EntityState]

    let connection: Connection
    var configuration: Configuration

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

    init(connection: Connection, configuration: Configuration) {
        self.connection = connection
        self.configuration = configuration

        encoder = JSONEncoder()
        decoder = JSONDecoder()
        decoder.userInfo = [.entityManager: self]
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
                try await connection.open()
                try await connection.beginTransaction()

                do {
                    for query in allQueries {
                        if let dictionary = try await doQuery(query.raw).first {
                            postInserts.append(dictionary)
                        }
                    }

                    try await connection.commitTransaction()
                    try await connection.close()
                    cleanUpDirty()
                } catch {
                    allQueries.removeAll()
                    try await connection.rollbackTransaction()
                    try await connection.close()
                    throw error
                }
            }
        } catch {
            allQueries.removeAll()
            throw error
        }
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
}

extension SQLEntityManager {
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
}

extension SQLEntityManager {
    private func mapping(from entityName: String) throws -> any EntityMapping {
        guard let mapping = configuration.mapping(entityName: entityName) else {
            throw TuproqError("Entity named \"\(entityName)\" is not registered.")
        }
        return mapping
    }

    private func table(from entityName: String) throws -> String {
        guard let table = configuration.mapping(entityName: entityName)?.table else {
            throw TuproqError("Entity named \"\(entityName)\" is not registered.")
        }
        return table
    }

    private func table<E: Entity>(from entityType: E.Type) throws -> String {
        guard let table = configuration.mapping(from: entityType)?.table else {
            throw TuproqError("Entity named \"\(entityType)\" is not registered.")
        }
        return table
    }
}

extension SQLEntityManager {
    func propertyChanged<E: Entity>(entity: E, propertyName: String, oldValue: Codable?, newValue: Codable?) {
        let entityName = Configuration.entityName(from: entity)
        let objectID = ObjectIdentifier(entity)
        guard identityMap[entityName]?[objectID] != nil else { return }
        entityUpdates[objectID] = entity
        let changeSet = [propertyName: (oldValue, newValue)]
        entityChangeSets[objectID] = changeSet
    }
}

extension SQLEntityManager {
    func createQueryBuilder() -> QB {
        QB()
    }

    func find<E: Entity>(_ entityType: E.Type, id: E.ID) async throws -> E? {
        guard !(id as AnyObject is NSNull) else { return nil }
        let id = id as AnyHashable
        let entityName = Configuration.entityName(from: entityType)

        if let objectID = objectIdentifiers[id], let entity = identityMap[entityName]?[objectID] {
            return entity as? E
        }

        let table = try table(from: entityType)
        let query = createQueryBuilder()
            .select()
            .from(table)
            .where("id = '\(id)'") // TODO: provide the id as arguments to the query method
            .getQuery()

        if let entity: E = try await self.query(query.raw).first {
            let objectID = ObjectIdentifier(entity)
            addEntityToIdentityMap(entity)
            entityStates[objectID] = .managed

            return entity
        }

        return nil
    }

    @discardableResult
    func query<E: Entity>(_ string: String, arguments parameters: [Codable?]) async throws -> [E] {
        let result = try await query(string, arguments: parameters)
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
    func query(_ string: String, arguments parameters: [Codable?]) async throws -> [[String: Any?]] {
        try await connection.open()
        let result = try await doQuery(string, arguments: parameters)
        try await connection.close()

        return result
    }

    private func doQuery(_ string: String, arguments parameters: [Codable?] = .init()) async throws -> [[String: Any?]] {
        let result = try await connection.query(string, arguments: parameters)

        if let result {
            let tableIDs = Set<Int32>(result.columns.map { $0.tableID })
            let tables = try await fetchTables(tableIDs: tableIDs)

            if tables.isEmpty {
                var array = [[String: Any?]]()

                for row in result.rows {
                    var dictionary = [String: Any?]()

                    for (index, column) in result.columns.enumerated() {
                        dictionary[column.name] = row[index]
                    }

                    array.append(dictionary)
                }

                return array
            }

            let columns = result.columns.map { ObjectHydration.Column(name: $0.name, table: tables[$0.tableID]!) }
            let rootTable = columns.map { $0.table }.first! // TODO: fix identifying root table

            return ObjectHydration(
                entityManager: self,
                result: .init(columns: columns, rows: result.rows),
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
        let result = try await connection.query(string, arguments: [Array(tableIDs)])

        if let result {
            for row in result.rows {
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
        let objectID = ObjectIdentifier(entity)
        guard entityMap[objectID] == nil else { return }

        if let state = entityStates[objectID] {
            switch state {
            case .removed:
                entityDeletions.removeValue(forKey: objectID)
                entityStates[objectID] = .managed
                entityMap[objectID] = entity
            case .detached: throw error(.detachedEntityCannotBePersisted(entity))
            default: break
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
    func remove<E: Entity>(_ entity: E) {
        var entityMap = EntityMap()
        remove(entity, visited: &entityMap)
    }

    private func remove<E: Entity>(_ entity: E, visited entityMap: inout EntityMap) {
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
    func refresh<E: Entity>(_ entity: inout E) throws {
        var entityMap = EntityMap()
        try refresh(&entity, visited: &entityMap)
    }

    private func refresh<E: Entity>(_ entity: inout E, visited entityMap: inout EntityMap) throws {
        let objectID = ObjectIdentifier(entity)
        guard entityMap[objectID] == nil else { return }
        entityMap[objectID] = entity

        if let state = entityStates[objectID] {
            switch state {
            case .managed:
                // TODO: implement
                break
            case .new:
                // TODO: implement
                break
            case .removed:
                // TODO: implement
                break
            default:
                // TODO: implement
                break
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
    private func prepareInserts(for entityName: String) throws {
        let mapping = try mapping(from: entityName)

        for entity in entityInsertions.values {
            if entityName == Configuration.entityName(from: entity) {
                var columns = [String]()
                var values = [Any?]()

                for (field, value) in try encodeToDictionary(entity) {
                    if mapping.children.contains(where: { $0.field == field }) ||
                        mapping.siblings.contains(where: { $0.field == field }) {
                        continue
                    }

                    if mapping.parents.contains(where: { $0.field == field }) {
                        let column = Configuration.namingStrategy.joinColumn(field: field)
                        columns.append(column)

                        if let value = value {
                            let valueDictionary = value as! [String: Any?]
                            values.append(valueDictionary["id"]!)
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

        for (objectID, entity) in entityUpdates {
            if let id = entityIdentifiers[objectID], entityName == Configuration.entityName(from: entity) {
                var values = [(String, Codable?)]()

                if let changeSet = entityChangeSets[objectID] {
                    for (key, (_, newValue)) in changeSet {
                        if let column = mapping.fields.first(where: { $0.field == key })?.column.name {
                            values.append((column, newValue))
                        } else if let column = mapping.parents.first(where: { $0.field == key })?.column.name {
                            values.append((column, newValue))
                        }
                    }

                    let query = createQueryBuilder()
                        .update(table: mapping.table, values: values)
                        .where("id = '\(id)'")
                        .returning()
                        .getQuery()
                    allQueries.append(query)
                }
            }
        }
    }

    private func prepareDeletions(for entityName: String) throws {
        let table = try table(from: entityName)

        for objectID in entityDeletions.keys {
            if let id = entityIdentifiers[objectID] {
                let query = createQueryBuilder()
                    .delete()
                    .from(table)
                    .where("id = '\(id)'")
                    .returning()
                    .getQuery()
                allQueries.append(query)
            }
        }
    }

    private func encodeToDictionary<E: Entity>(_ entity: E) throws -> [String: Any?] {
        let data = try encoder.encode(entity)
        guard let dictionary = try JSONSerialization.jsonObject(
            with: data,
            options: .fragmentsAllowed
        ) as? [String: Any?] else {
            throw error(.entityToDictionaryFailed)
        }

        return dictionary
    }
}
