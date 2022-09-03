import Foundation

final class SQLEntityManager<QB: SQLQueryBuilder>: EntityManager {
    private typealias ChangeSet = [String: (Codable?, Codable?)] // [property: (oldValue, newValue)]
    private typealias EntityMap = [String: Any?]

    let connection: Connection
    private var allQueries = ""

    private var entityChangeSets = [String: [AnyHashable: ChangeSet]]()

    private var entityDeletions = [String: [AnyHashable: EntityMap]]()
    private var entityInsertions = [String: [AnyHashable: EntityMap]]()
    private var entityUpdates = [String: [AnyHashable: EntityMap]]()

    private var entityStates = [AnyHashable: EntityState]()
    private var identityMap = [String: [AnyHashable: EntityMap]]()
    private var repositories = [String: AnyRepository]()

    init(connection: Connection) {
        self.connection = connection

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

    func find<E: Entity, I: Hashable>(_ entityType: E.Type, id: I) async throws -> E? {
        let query = createQueryBuilder()
            .select()
            .from(E.entity)
            .where("id = \"\(id)\"")
            .getQuery()

        if let result = try await connection.query(query.raw), let row = result.rows.first {
            var dictionary = [String: Any?]()

            for (index, value) in row.enumerated() {
                let column = result.columns[index]
                dictionary[column] = value
            }

            let entity = try dictionary.decode(to: E.self)
            entityStates[entity.id] = .managed
            addToIdentityMap(entity: entity)

            return entity
        }

        return nil
    }

    func flush() async throws {
        do {
            let insertedIDsMap = try prepareInserts()
            prepareUpdates()
            prepareDeletions()

            if !allQueries.isEmpty {
                allQueries = "BEGIN;\(allQueries)COMMIT;"
                var postInserts = [[String: Any?]]()

                if let result = try await connection.query(allQueries) {
                    for row in result.rows {
                        var dictionary = [String: Any?]()

                        for (index, value) in row.enumerated() {
                            let column = result.columns[index]
                            dictionary[column] = value
                        }

                        postInserts.append(dictionary)
                    }
                }

                postFlush(insertedIDsMap: insertedIDsMap, postInserts: postInserts)
            }
        } catch {
            allQueries = ""
            throw error
        }
    }

    private func prepareInserts() throws -> [String: [AnyHashable]] {
        var idsMap = [String: [AnyHashable]]()

        for (table, entityMap) in entityInsertions {
            for (id, dictionary) in entityMap {
                var columns = [String]()
                var values = [Codable?]()

                for (key, value) in dictionary {
                    columns.append(key)

                    if let value = value as? Codable {
                        if let valueDictionary = value as? [String: Codable?] {
                            values.append(valueDictionary["id"]!)
                        } else {
                            values.append(value)
                        }
                    } else {
                        values.append("NULL") // TODO: it may not be necessary
                    }
                }

                if idsMap[table] == nil {
                    idsMap[table] = [id]
                } else {
                    idsMap[table]?.append(id)
                }

                let query = createQueryBuilder()
                    .insert(into: table, columns: columns, values: values)
                    .returning()
                    .getQuery()
                allQueries += "\(query);"
            }
        }

        return idsMap
    }

    private func prepareUpdates() {
        for (table, entityMap) in entityUpdates {
            for id in entityMap.keys {
                var values = [(String, Codable?)]()

                if let changeSet = entityChangeSets[table]?[id] {
                    for (key, (_, newValue)) in changeSet {
                        if let value = newValue {
                            values.append((key, value))
                        } else {
                            values.append((key, "NULL"))
                        }
                    }

                    let query = createQueryBuilder()
                        .update(table: table, values: values).where("id = \"\(id)\"")
                        .returning()
                        .getQuery()
                    allQueries += "\(query);"
                }
            }
        }
    }

    private func prepareDeletions() {
        for (table, entityMap) in entityDeletions {
            for id in entityMap.keys {
                let query = createQueryBuilder()
                    .delete()
                    .from(table).where("id = \"\(id)\"")
                    .returning()
                    .getQuery()
                allQueries += "\(query);"
            }
        }
    }

    private func postFlush(insertedIDsMap: [String: [AnyHashable]], postInserts: [[String: Any?]]) {
        for (table, insertedIDs) in insertedIDsMap {
            for (index, insertedID) in insertedIDs.enumerated() {
                let postInsert = postInserts[index]
                let postInsertID = postInsert["id"] as! AnyHashable

                for (name, value) in postInsert {
                    let property: [String: Any?] = [
                        "name": name,
                        "value": value
                    ]
                    let dictionary: [String: Any?] = [
                        "entity": table,
                        "id": insertedID,
                        "property": property
                    ]
                    NotificationCenter.default.post(name: propertyPostFlushValueChanged, object: dictionary)
                }

                if insertedID != postInsertID {
                    entityStates.removeValue(forKey: insertedID)
                    entityStates[postInsertID] = .managed
                    removeFromIdentityMap(entityName: table, id: insertedID)
                    addToIdentityMap(entityName: table, entityMap: postInsert, id: postInsertID)
                }
            }
        }

        for (table, entityMap) in entityDeletions {
            for id in entityMap.keys {
                entityStates.removeValue(forKey: id)
                removeFromIdentityMap(entityName: table, id: id)
            }
        }

        entityInsertions.removeAll()
        entityUpdates.removeAll()
        entityChangeSets.removeAll()
        entityDeletions.removeAll()
        allQueries = ""
    }

    func getRepository<R: Repository>(_ repositoryType: R.Type) -> R {
        let entityName = repositoryType.E.entity

        if let repository = repositories[entityName] {
            return repository.repository as! R
        }

        let repository = R()
        repositories[entityName] = AnyRepository(repository)

        return repository
    }

    func persist<E: Entity>(_ entity: inout E) throws {
        var entities = [AnyHashable: EntityMap]()
        try persist(&entity, visited: &entities)
    }

    private func persist<E: Entity>(_ entity: inout E, visited entities: inout [AnyHashable: EntityMap]) throws {
        // Set entityID in Field property wrappers
        let dictionary = try entity.asDictionary()
        entity = try dictionary.decode(to: E.self)

        let id: AnyHashable

        if entity.id as AnyObject is NSNull { // Check if an associatedtype Entity.ID is nil
            id = ObjectIdentifier(entity)
        } else {
            id = entity.id
        }

        guard entities[id] == nil else { return }
        entities[id] = try! entity.asDictionary()

        if let entityState = entityStates[id] {
            switch entityState {
            case .detached: break // TODO: implement
            case .managed: break
            case .new:
                insert(entity: entity, id: id)
                addToIdentityMap(entity: entity)
            case .removed:
                entityDeletions[E.entity]?.removeValue(forKey: id)
                addToIdentityMap(entity: entity)
                entityStates[id] = .managed
            }
        } else {
            insert(entity: entity, id: id)
            addToIdentityMap(entity: entity)
            entityStates[id] = .new
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
        let id = entity.id
        guard entities[id] == nil else { return }
        entities[id] = try! entity.asDictionary()
        let entityState = entityStates[id]

        switch entityState {
        case .managed:
            remove(entity: entity, id: id)
            entityStates[id] = .removed
        case .new:
            entityInsertions[E.entity]?.removeValue(forKey: id)
            removeFromIdentityMap(entity: entity)
            entityStates.removeValue(forKey: id)
        default: break
        }
    }

    private func insert<E: Entity>(entity: E, id: AnyHashable) {
        if entityInsertions[E.entity] == nil {
            entityInsertions[E.entity] = [id: try! entity.asDictionary()]
        } else {
            entityInsertions[E.entity]?[id] = try! entity.asDictionary()
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
        if entityDeletions[E.entity] == nil {
            entityDeletions[E.entity] = [id: try! entity.asDictionary()]
        } else {
            entityDeletions[E.entity]?[id] = try! entity.asDictionary()
        }
    }

    private func addToIdentityMap<E: Entity>(entity: E) {
        addToIdentityMap(entityName: E.entity, entityMap: try! entity.asDictionary(), id: entity.id)
    }

    private func addToIdentityMap(entityName: String, entityMap: EntityMap, id: AnyHashable) {
        if identityMap[entityName] == nil {
            identityMap[entityName] = [id: entityMap]
        } else {
            identityMap[entityName]?[id] = entityMap
        }
    }

    private func removeFromIdentityMap<E: Entity>(entity: E) {
        removeFromIdentityMap(entityName: E.entity, id: entity.id)
    }

    private func removeFromIdentityMap(entityName: String, id: AnyHashable) {
        identityMap[entityName]?.removeValue(forKey: id)
    }
}
