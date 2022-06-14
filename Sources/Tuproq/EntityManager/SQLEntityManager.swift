import Foundation

final class SQLEntityManager: EntityManager {
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
                var entityName = dictionary["entity"] as! String
                entityName = entityName.components(separatedBy: ".").last!
                var entityID = dictionary["id"] as! AnyHashable

                if let uuid = UUID(uuidString: String(describing: entityID)) { // TODO: check if the field type is UUID
                    entityID = AnyHashable(uuid)
                }

                let property = dictionary["property"] as! [String: Any?]
                let propertyName = property["name"] as! String
                let propertyOldValue = property["oldValue"] as? Codable
                let propertyNewValue = property["newValue"] as? Codable
                let entity = identityMap[entityName]![entityID]!

                if entityUpdates[entityName] == nil {
                    entityUpdates[entityName] = [entityID: entity]
                } else {
                    entityUpdates[entityName]?[entityID] = entity
                }

                if entityChangeSets[entityName] == nil {
                    entityChangeSets[entityName] = [entityID: [propertyName: (propertyOldValue, propertyNewValue)]]
                } else {
                    entityChangeSets[entityName]?[entityID] = [propertyName: (propertyOldValue, propertyNewValue)]
                }
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: propertyValueChanged, object: nil)
    }

    func createQueryBuilder() -> SQLQueryBuilder {
        SQLQueryBuilder()
    }

    func find<E: Entity, I: Hashable>(_ entityType: E.Type, id: I) async throws -> E? {
        let query = createQueryBuilder()
            .select()
            .from(E.entity)
            .where("id = \"\(id)\"")
            .getQuery()

        if let dictionary = try await connection.connection.simpleQuery(query.raw)?.data.first {
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

                if let data = try await connection.connection.simpleQuery(allQueries)?.data {
                    postInserts = data
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
                var values = [Any?]()

                for (key, value) in dictionary {
                    columns.append(key)

                    if let value = value {
                        values.append(value)
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
                var values = [(String, Any?)]()

                if let changeSet = entityChangeSets[table]?[id] {
                    for (key, (_, newValue)) in changeSet {
                        if let value = newValue {
                            values.append((key, value))
                        } else {
                            values.append((key, "NULL"))
                        }
                    }

                    let query = createQueryBuilder()
                        .update(table, set: values).where("id = \"\(id)\"")
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

        let entityID: AnyHashable

        if entity.id as AnyObject is NSNull { // Check if an associatedtype Entity.ID is nil
            entityID = ObjectIdentifier(entity)
        } else {
            entityID = entity.id
        }

        guard entities[entityID] == nil else { return }
        entities[entityID] = try! entity.asDictionary()

        if let entityState = entityStates[entityID] {
            switch entityState {
            case .managed: break
            case .new:
                if entityInsertions[E.entity] == nil {
                    entityInsertions[E.entity] = [entityID: try! entity.asDictionary()]
                } else {
                    entityInsertions[E.entity]?[entityID] = try! entity.asDictionary()
                }

                addToIdentityMap(entity: entity)
            case .removed:
                entityDeletions[E.entity]?.removeValue(forKey: entityID)
                addToIdentityMap(entity: entity)
                entityStates[entityID] = .managed
            }
        } else {
            if entityInsertions[E.entity] == nil {
                entityInsertions[E.entity] = [entityID: try! entity.asDictionary()]
            } else {
                entityInsertions[E.entity]?[entityID] = try! entity.asDictionary()
            }

            addToIdentityMap(entity: entity)
            entityStates[entityID] = .new
        }
    }

    func refresh<E: Entity>(_ entity: inout E) throws {
        var entities = [AnyHashable: EntityMap]()
        try refresh(&entity, visited: &entities)
    }

    private func refresh<E: Entity>(_ entity: inout E, visited entities: inout [AnyHashable: EntityMap]) throws {
        let entityID = entity.id
        guard entities[entityID] == nil else { return }
        entities[entityID] = try! entity.asDictionary()
        let entityState = entityStates[entityID]

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
        let entityID = entity.id
        guard entities[entityID] == nil else { return }
        entities[entityID] = try! entity.asDictionary()
        let entityState = entityStates[entityID]

        switch entityState {
        case .managed:
            if entityDeletions[E.entity] == nil {
                entityDeletions[E.entity] = [entityID: try! entity.asDictionary()]
            } else {
                entityDeletions[E.entity]?[entityID] = try! entity.asDictionary()
            }

            entityStates[entityID] = .removed
        case .new:
            entityInsertions[E.entity]?.removeValue(forKey: entityID)
            removeFromIdentityMap(entity: entity)
            entityStates.removeValue(forKey: entityID)
        default: break
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

extension SQLEntityManager {
    enum EntityState {
        case new
        case managed
        case removed
    }
}
