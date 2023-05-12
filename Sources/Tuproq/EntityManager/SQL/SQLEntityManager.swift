import Foundation

final class SQLEntityManager<QB: SQLQueryBuilder>: EntityManager {
    private typealias ChangeSet = [String: (Codable?, Codable?)] // [property: (oldValue, newValue)]
    private typealias EntityMap = [String: Any?]
    private typealias EntityChanges = [String: [AnyHashable: EntityMap]]

    let connection: Connection
    var configuration: Configuration
    private var allQueries = [any Query]()

    private var entityChangeSets = [String: [AnyHashable: ChangeSet]]()

    private var entityDeletions = EntityChanges()
    private var entityInsertions = EntityChanges()
    private var entityUpdates = EntityChanges()

    private var entityStates = [AnyHashable: EntityState]()
    private var identityMap = EntityChanges()

    init(connection: Connection, configuration: Configuration) {
        self.connection = connection
        self.configuration = configuration

        NotificationCenter.default.addObserver(
            forName: propertyValueChanged,
            object: nil,
            queue: nil
        ) { [self] notification in
            if let dictionary = notification.object as? [String: Any?] {
                var entity = dictionary["entity"] as! String
                entity = entity.components(separatedBy: ".").last!
                var id = dictionary["id"] as! AnyHashable

                if let uuid = UUID(uuidString: String(describing: id)) { // TODO: check if the field type is UUID
                    id = AnyHashable(uuid)
                }

                let property = dictionary["property"] as! [String: Any?]
                let propertyName = property["name"] as! String
                let propertyOldValue = property["oldValue"] as? Codable
                let propertyNewValue = property["newValue"] as? Codable
                update(
                    entity: entity,
                    id: id,
                    changeSet: [propertyName: (propertyOldValue, propertyNewValue)]
                )
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: propertyValueChanged, object: nil)
    }

    func createQueryBuilder() -> QB {
        QB()
    }

    func find<E: Entity>(_ entityType: E.Type, id: E.Identifiable) async throws -> E? {
        guard !(id as AnyObject is NSNull) else { return nil }
        let id = id as AnyHashable
        let table = try table(from: entityType)
        let query = createQueryBuilder()
            .select()
            .from(table)
            .where("id = \"\(id)\"")
            .getQuery()

        if let dictionary = try await connection.query(query.raw).first {
            let entity = try dictionary.decode(to: E.self, entityID: id)
            entityStates[entity.id] = .managed
            let entityName = Configuration.entityName(from: entityType)
            addToIdentityMap(entityName: entityName, id: entity.id, dictionary: dictionary)

            return entity
        }

        return nil
    }

    func flush() async throws {
        do {
            let commitOrder = try getCommitOrder()
            var insertedIDsMap = [String: [AnyHashable]]()

            for entityName in commitOrder {
                insertedIDsMap[entityName] = try prepareInserts(entityName: entityName)
            }

            for entityName in commitOrder {
                try prepareUpdates(entityName: entityName)
            }

            for entityName in commitOrder {
                try prepareDeletions(entityName: entityName)
            }

            if !allQueries.isEmpty {
                var postInserts = [[String: Any?]]()
                try await connection.open()
                try await connection.query("BEGIN;")

                for query in allQueries {
                    if let dictionary = try await connection.query(query.raw).first {
                        postInserts.append(dictionary)
                    }
                }

                try await connection.query("COMMIT;")
                try postFlush(insertedIDsMap: insertedIDsMap, postInserts: postInserts)
                try await connection.close()
            }
        } catch {
            allQueries.removeAll()
            throw error
        }
    }

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

    private func mapping(from entityName: String) throws -> any EntityMapping {
        guard let mapping = configuration.mapping(from: entityName) else {
            throw TuproqError("Entity named \"\(entityName)\" is not registered.")
        }
        return mapping
    }

    private func table(from entityName: String) throws -> String {
        guard let table = configuration.mapping(from: entityName)?.table else {
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

    private func prepareInserts(entityName: String) throws -> [AnyHashable] {
        var ids = [AnyHashable]()

        if let entityMap = entityInsertions[entityName] {
            let mapping = try mapping(from: entityName)

            for (id, dictionary) in entityMap {
                var columns = [String]()
                var values = [Any?]()

                for (field, value) in dictionary {
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

    private func prepareUpdates(entityName: String) throws {
        if let entityMap = entityUpdates[entityName] {
            let mapping = try mapping(from: entityName)

            for id in entityMap.keys {
                var values = [(String, Codable?)]()

                if let changeSet = entityChangeSets[entityName]?[id] {
                    for (key, (_, newValue)) in changeSet {
                        if let value = newValue {
                            values.append((key, value))
                        } else {
                            values.append((key, "\(SQLExpression.Kind.null)"))
                        }
                    }

                    let query = createQueryBuilder()
                        .update(table: mapping.table, values: values)
                        .where("id = \"\(id)\"")
                        .returning()
                        .getQuery()
                    allQueries.append(query)
                }
            }
        }
    }

    private func prepareDeletions(entityName: String) throws {
        if let entityMap = entityDeletions[entityName] {
            let table = try table(from: entityName)

            for id in entityMap.keys {
                let query = createQueryBuilder()
                    .delete()
                    .from(table)
                    .where("id = \"\(id)\"")
                    .returning()
                    .getQuery()
                allQueries.append(query)
            }
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
                    NotificationCenter.default.post(name: propertyPostFlushValueChanged, object: dictionary)
                }

                if insertedID != postInsertID {
                    entityStates.removeValue(forKey: insertedID)
                    entityStates[postInsertID] = .managed
                    removeFromIdentityMap(entityName: entityName, id: insertedID)
                    addToIdentityMap(entityName: entityName, entityMap: postInsert, id: postInsertID)
                }
            }
        }

        for (entityName, entityMap) in entityDeletions {
            for id in entityMap.keys {
                entityStates.removeValue(forKey: id)
                removeFromIdentityMap(entityName: entityName, id: id)
            }
        }

        entityInsertions.removeAll()
        entityUpdates.removeAll()
        entityChangeSets.removeAll()
        entityDeletions.removeAll()
        allQueries.removeAll()
    }

    func persist<E: Entity>(_ entity: inout E) throws {
        var entities = [AnyHashable: EntityMap]()
        try persist(&entity, visited: &entities)
    }

    private func persist<E: Entity>(_ entity: inout E, visited entities: inout [AnyHashable: EntityMap]) throws {
        let dictionary = try entity.asDictionary()
        let entityID: AnyHashable

        if let id = dictionary["id"] as? AnyHashable {
            entityID = id
        } else {
            entityID = ObjectIdentifier(entity)
        }

        // Set entityID in Observed property wrappers
        entity = try dictionary.decode(to: E.self, entityID: entityID)

        guard entities[entityID] == nil else { return }
        entities[entityID] = dictionary
        let entityName = Configuration.entityName(from: entity)

        if let entityState = entityStates[entityID] {
            switch entityState {
            case .detached: break // TODO: implement
            case .managed: break
            case .new:
                insert(entityName: entityName, id: entityID, dictionary: dictionary)
                addToIdentityMap(entityName: entityName, id: entityID, dictionary: dictionary)
            case .removed:
                entityDeletions[entityName]?.removeValue(forKey: entityID)
                addToIdentityMap(entityName: entityName, id: entityID, dictionary: dictionary)
                entityStates[entityID] = .managed
            }
        } else {
            insert(entityName: entityName, id: entityID, dictionary: dictionary)
            addToIdentityMap(entityName: entityName, id: entityID, dictionary: dictionary)
            entityStates[entityID] = .new
        }

        try cascadePersist(&entity, visited: &entities)
    }

    private func cascadePersist<E: Entity>(
        _ entity: inout E,
        visited entities: inout [AnyHashable: EntityMap]
    ) throws {
        // TODO: implement
    }

    func refresh<E: Entity>(_ entity: inout E) throws {
        var entities = [AnyHashable: EntityMap]()
        try refresh(&entity, visited: &entities)
    }

    private func refresh<E: Entity>(_ entity: inout E, visited entities: inout [AnyHashable: EntityMap]) throws {
        let id = entity.id
        guard entities[id] == nil else { return }
        entities[id] = try! entity.asDictionary()
        let entityState = entityStates[id]

        switch entityState {
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

    func remove<E: Entity>(_ entity: E) {
        var entities = [AnyHashable: EntityMap]()
        remove(entity, visited: &entities)
    }

    private func remove<E: Entity>(_ entity: E, visited entities: inout [AnyHashable: EntityMap]) {
        let entityName = Configuration.entityName(from: entity)
        let id = entity.id
        guard entities[id] == nil else { return }
        entities[id] = try! entity.asDictionary()
        let entityState = entityStates[id]

        switch entityState {
        case .managed:
            remove(entity: entity, id: id)
            entityStates[id] = .removed
        case .new:
            entityInsertions[entityName]?.removeValue(forKey: id)
            removeFromIdentityMap(entity: entity)
            entityStates.removeValue(forKey: id)
        default: break
        }
    }

    private func insert(entityName: String, id: AnyHashable, dictionary: [String: Any?]) {
        if entityInsertions[entityName] == nil {
            entityInsertions[entityName] = [id: dictionary]
        } else {
            entityInsertions[entityName]?[id] = dictionary
        }
    }

    private func update(entity: String, id: AnyHashable, changeSet: ChangeSet) {
        let entityMap = identityMap[entity]![id]!

        if entityUpdates[entity] == nil {
            entityUpdates[entity] = [id: entityMap]
        } else {
            entityUpdates[entity]?[id] = entityMap
        }

        if entityChangeSets[entity] == nil {
            entityChangeSets[entity] = [id: changeSet]
        } else {
            entityChangeSets[entity]?[id] = changeSet
        }
    }

    private func remove<E: Entity>(entity: E, id: AnyHashable) {
        let entityName = Configuration.entityName(from: entity)

        if entityDeletions[entityName] == nil {
            entityDeletions[entityName] = [id: try! entity.asDictionary()]
        } else {
            entityDeletions[entityName]?[id] = try! entity.asDictionary()
        }
    }

    private func addToIdentityMap(entityName: String, id: AnyHashable, dictionary: [String: Any?]) {
        addToIdentityMap(entityName: entityName, entityMap: dictionary, id: id)
    }

    private func addToIdentityMap(entityName: String, entityMap: EntityMap, id: AnyHashable) {
        if identityMap[entityName] == nil {
            identityMap[entityName] = [id: entityMap]
        } else {
            identityMap[entityName]?[id] = entityMap
        }
    }

    private func removeFromIdentityMap<E: Entity>(entity: E) {
        let entityName = Configuration.entityName(from: entity)
        removeFromIdentityMap(entityName: entityName, id: entity.id)
    }

    private func removeFromIdentityMap(entityName: String, id: AnyHashable) {
        identityMap[entityName]?.removeValue(forKey: id)
    }
}
