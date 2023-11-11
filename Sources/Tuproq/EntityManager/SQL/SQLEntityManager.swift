import Foundation

final class SQLEntityManager<QB: SQLQueryBuilder>: EntityManager {
    private typealias ChangeSet = [String: (Codable?, Codable?)] // [property: (oldValue, newValue)]
    private typealias EntityChanges = [String: EntityMap]
    private typealias EntityMap = [AnyHashable: any Entity]

    let connection: Connection
    var configuration: Configuration

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private var allQueries = [any Query]()
    private var entityDeletions = EntityChanges()
    private var entityInsertions = EntityChanges()
    private var entityUpdates = EntityChanges()
    private var entityStates = [String: [AnyHashable: EntityState]]()
    private var entityChangeSets = [String: [AnyHashable: ChangeSet]]()
    private var identityMap = EntityChanges()

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
            var insertedIDsMap = [String: [AnyHashable]]()

            for entityName in commitOrder {
                insertedIDsMap[entityName] = try prepareInserts(for: entityName)
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
                    try postFlush(insertedIDsMap: insertedIDsMap, postInserts: postInserts)
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

    private func postFlush(insertedIDsMap: [String: [AnyHashable]], postInserts: [[String: Any?]]) throws {
        guard !postInserts.isEmpty else { return }

        for (entityName, insertedIDs) in insertedIDsMap {
            for (index, insertedID) in insertedIDs.enumerated() {
                let postInsert = postInserts[index]
                let postInsertID = postInsert["id"] as! AnyHashable

                for (name, value) in postInsert {
                    let property: [String: Any?] = [
                        "name": name,
                        "value": value
                    ]
                    let dictionary: [String: Any?] = [
                        "entity": entityName,
                        "oldID": insertedID,
                        "newID": postInsertID,
                        "property": property
                    ]
                    NotificationCenter.default.post(name: .propertyPostFlushValueChanged, object: dictionary)
                }

                if insertedID != postInsertID {
//                    entityStates.removeValue(forKey: insertedID)
//                    entityStates[postInsertID] = .managed
//                    removeFromIdentityMap(entityName: entityName, id: insertedID)
//                    addEntityToIdentityMap(entityName: entityName, entityMap: postInsert, id: postInsertID) // TODO: fix
                }
            }
        }

        for entityMap in entityDeletions.values {
            for entity in entityMap.values {
                removeEntityFromIdentityMap(entity)
                removeEntityState(for: entity)
            }
        }

        cleanUp()
    }

    private func cleanUp() {
        entityInsertions.removeAll()
        entityUpdates.removeAll()
        entityChangeSets.removeAll()
        entityDeletions.removeAll()
        allQueries.removeAll()
    }
}

extension SQLEntityManager {
    private func getCommitOrder() throws -> [String] {
        let calculator = CommitOrderCalculator()
        var entityNames = [String]()

        func processEntityChanges(_ entityChanges: EntityChanges) {
            for entityName in entityChanges.keys {
                let node = CommitOrderCalculator.Node(value: entityName)

                if !calculator.hasNode(node) {
                    calculator.addNode(node)
                    entityNames.append(entityName)
                }
            }
        }

        processEntityChanges(entityInsertions)
        processEntityChanges(entityUpdates)
        processEntityChanges(entityDeletions)

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
        let id = entity.id
        guard let entityMaps = identityMap[entityName], let entityMap = entityMaps[id] else { return }

        if entityUpdates[entityName] == nil {
            entityUpdates[entityName] = [id: entityMap]
        } else {
            entityUpdates[entityName]?[id] = entityMap
        }

        let changeSet = [propertyName: (oldValue, newValue)]

        if entityChangeSets[entityName] == nil {
            entityChangeSets[entityName] = [id: changeSet]
        } else {
            var existingChangeSet = entityChangeSets[entityName]![id]!
            existingChangeSet.merge(changeSet) { (_, new) in new }
            entityChangeSets[entityName]?[id] = existingChangeSet
        }
    }
}

extension SQLEntityManager {
    func createQueryBuilder() -> QB {
        QB()
    }

    func find<E: Entity>(_ entityType: E.Type, id: E.ID) async throws -> E? {
        guard !(id as AnyObject is NSNull) else { return nil }
        let id = id as AnyHashable
        let table = try table(from: entityType)
        let query = createQueryBuilder()
            .select()
            .from(table)
            .where("id = '\(id)'") // TODO: provide the id as arguments to the query method
            .getQuery()

        if let entity: E = try await self.query(query.raw).first {
            addEntityToIdentityMap(entity)
            setEntityState(.managed, for: entity)

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
            addEntityToIdentityMap(entity)
            setEntityState(.managed, for: entity)
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
        var entities = EntityMap()
        try persist(&entity, visited: &entities)
    }

    private func persist<E: Entity>(_ entity: inout E, visited entities: inout EntityMap) throws {
        let objectID = ObjectIdentifier(entity)
        guard entities[objectID] == nil else { return }
        entities[objectID] = entity

        switch getEntityState(for: entity) {
        case .new: try persistNew(&entity)
        case .removed: persistRemoved(entity)
        case .managed: break
        case .detached: throw error(.detachedEntityCannotBePersisted(entity))
        }

        try cascadePersist(&entity, visited: &entities)
    }

    private func persistNew<E: Entity>(_ entity: inout E) throws {
        let data = try JSONSerialization.data(withJSONObject: try encodeToDictionary(entity))
        entity = try decoder.decode(E.self, from: data)
        addEntityToIdentityMap(entity)
        insertEntity(entity)
        setEntityState(.managed, for: entity)
    }

    private func persistRemoved<E: Entity>(_ entity: E) {
        removeDeletedEntity(entity)
        setEntityState(.managed, for: entity)
    }

    private func cascadePersist<E: Entity>(
        _ entity: inout E,
        visited entities: inout EntityMap
    ) throws {
        // TODO: implement
    }
}

extension SQLEntityManager {
    func remove<E: Entity>(_ entity: E) {
        var entities = EntityMap()
        remove(entity, visited: &entities)
    }

    private func remove<E: Entity>(_ entity: E, visited entities: inout EntityMap) {
        let id = entity.id
        guard entities[id] == nil else { return }
        entities[id] = entity

        switch getEntityState(for: entity) {
        case .managed:
            doRemove(entity)
            setEntityState(.removed, for: entity)
        case .new:
            removeEntityFromIdentityMap(entity)
            removeInsertedEntity(entity)
            removeEntityState(for: entity)
        default: break
        }
    }

    private func doRemove<E: Entity>(_ entity: E) {
        let entityName = Configuration.entityName(from: entity)
        let id = entity.id

        if entityDeletions[entityName] == nil {
            entityDeletions[entityName] = [id: entity]
        } else {
            entityDeletions[entityName]?[id] = entity
        }
    }
}

extension SQLEntityManager {
    func refresh<E: Entity>(_ entity: inout E) throws {
        var entities = EntityMap()
        try refresh(&entity, visited: &entities)
    }

    private func refresh<E: Entity>(_ entity: inout E, visited entities: inout EntityMap) throws {
        let id = entity.id
        guard entities[id] == nil else { return }
        entities[id] = entity

        switch getEntityState(for: entity) {
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

extension SQLEntityManager {
    private func prepareInserts(for entityName: String) throws -> [AnyHashable] {
        var ids = [AnyHashable]()

        if let entityMap = entityInsertions[entityName] {
            let mapping = try mapping(from: entityName)

            for (id, entity) in entityMap {
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

                ids.append(id)

                let query = createQueryBuilder()
                    .insert(into: mapping.table, columns: columns, values: values)
                    .returning()
                    .getQuery()
                allQueries.append(query)
            }
        }

        return ids
    }

    private func prepareUpdates(for entityName: String) throws {
        if let entityMap = entityUpdates[entityName] {
            let mapping = try mapping(from: entityName)

            for id in entityMap.keys {
                var values = [(String, Codable?)]()

                if let changeSet = entityChangeSets[entityName]?[id] {
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
        if let entityMap = entityDeletions[entityName] {
            let table = try table(from: entityName)

            for id in entityMap.keys {
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

extension SQLEntityManager {
    private func addEntityToIdentityMap<E: Entity>(_ entity: E) {
        let entityName = Configuration.entityName(from: entity)
        let id = entity.id

        if identityMap[entityName] == nil {
            identityMap[entityName] = [id: entity]
        } else {
            identityMap[entityName]?[id] = entity
        }
    }

    private func removeEntityFromIdentityMap<E: Entity>(_ entity: E) {
        let entityName = Configuration.entityName(from: entity)
        identityMap[entityName]?.removeValue(forKey: entity.id)

        if let entityMap = identityMap[entityName], entityMap.isEmpty {
            identityMap.removeValue(forKey: entityName)
        }
    }
}

extension SQLEntityManager {
    private func insertEntity<E: Entity>(_ entity: E) {
        let entityName = Configuration.entityName(from: entity)
        let id = entity.id

        if entityInsertions[entityName] == nil {
            entityInsertions[entityName] = [id: entity]
        } else {
            entityInsertions[entityName]?[id] = entity
        }
    }

    private func removeInsertedEntity<E: Entity>(_ entity: E) {
        let entityName = Configuration.entityName(from: entity)
        entityInsertions[entityName]?.removeValue(forKey: entity.id)

        if let entityMap = entityInsertions[entityName], entityMap.isEmpty {
            entityInsertions.removeValue(forKey: entityName)
        }
    }

    private func removeDeletedEntity<E: Entity>(_ entity: E) {
        let entityName = Configuration.entityName(from: entity)
        entityDeletions[entityName]?.removeValue(forKey: entity.id)

        if let entityMap = entityDeletions[entityName], entityMap.isEmpty {
            entityDeletions.removeValue(forKey: entityName)
        }
    }
}

extension SQLEntityManager {
    private func setEntityState<E: Entity>(_ state: EntityState, for entity: E) {
        let entityName = Configuration.entityName(from: entity)

        if entityStates[entityName] == nil {
            entityStates[entityName] = [entity.id: state]
        } else {
            entityStates[entityName]?[entity.id] = state
        }
    }

    private func getEntityState<E: Entity>(for entity: E, default state: EntityState = .new) -> EntityState {
        let entityName = Configuration.entityName(from: entity)
        return entityStates[entityName]?[entity.id] ?? state
    }

    private func removeEntityState<E: Entity>(for entity: E) {
        let entityName = Configuration.entityName(from: entity)
        entityStates[entityName]?.removeValue(forKey: entity.id)

        if let entityMap = entityStates[entityName], entityMap.isEmpty {
            entityStates.removeValue(forKey: entityName)
        }
    }
}
