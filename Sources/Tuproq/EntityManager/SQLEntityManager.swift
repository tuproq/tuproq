import Foundation

final class SQLEntityManager: EntityManager {
    private typealias ChangeSet = [String: (Codable?, Codable?)] // [propertyName: (oldValue, newValue)]

    let connection: Connection

    private var entityChangeSets = [AnyHashable: ChangeSet]()

    private var entityDeletions = [AnyHashable: AnyEntity]()
    private var entityInsertions = [AnyHashable: AnyEntity]()
    private var entityUpdates = [AnyHashable: AnyEntity]()

    private var entityStates = [AnyHashable: EntityState]()
    private var identityMap = [String: [AnyHashable: AnyEntity]]()
    private var repositories = [String: AnyRepository]()

    init(connection: Connection) {
        self.connection = connection
        NotificationCenter.default.addObserver(
            forName: propertyValueChanged,
            object: nil,
            queue: nil
        ) { [self] notification in
            if let dictionary = notification.object as? [String: Any?] {
                var entityName = dictionary["entityName"] as! String
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
                entityUpdates[entityID] = entity
                entityChangeSets[entityID] = [propertyName: (propertyOldValue, propertyNewValue)]
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: propertyValueChanged, object: nil)
    }

    func createQueryBuilder() -> SQLQueryBuilder {
        SQLQueryBuilder()
    }

    func detach<E: Entity>(_ entity: E) {
        var entities = [AnyHashable: AnyEntity]()
        detach(entity, visited: &entities)
    }

    private func detach<E: Entity>(_ entity: E, visited entities: inout [AnyHashable: AnyEntity]) {
        let entityID = entity.id
        guard entities[entityID] == nil else { return }
        entities[entityID] = AnyEntity(entity)
        let entityState = entityStates[entityID]

        // TODO: implement
    }

    func find<E: Entity, I: Hashable>(_ entityType: E.Type, id: I) async throws -> E? {
        let query = createQueryBuilder()
            .select()
            .from(E.entity)
            .where("id = \"\(id)\"")
            .getQuery()

        if let dictionary = try await connection.connection.simpleQuery(query.raw).first {
            let entity = try dictionary.decode(to: E.self)
            entityStates[entity.id] = .managed
            addToIdentityMap(entity)

            return entity
        }

        return nil
    }

    func flush() async throws {
        var allQueries = ""
        let queryBuilder = createQueryBuilder()

        for entity in entityInsertions.values {
            let dictionary = try entity.entity.asDictionary()
            let table = entity.name
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

            let query = queryBuilder.insert(into: table, columns: columns, values: values).getQuery()
            allQueries += "\(query);"
        }

        for (id, entity) in entityUpdates {
            let table = entity.name
            var values = [(String, Any?)]()

            if let changeSet = entityChangeSets[id] {
                for (key, (_, newValue)) in changeSet {
                    if let value = newValue {
                        values.append((key, value))
                    } else {
                        values.append((key, "NULL"))
                    }
                }

                let query = queryBuilder.update(table, set: values).where("id = \"\(id)\"").getQuery()
                allQueries += "\(query);"
            }
        }

        for (id, entity) in entityDeletions {
            let table = entity.name
            let query = queryBuilder.delete().from(table).where("id = \"\(id)\"").getQuery()
            allQueries += "\(query);"
        }

        if !allQueries.isEmpty {
            allQueries = "BEGIN;\(allQueries)COMMIT;"

            try await connection.connection.simpleQuery(allQueries)

            for id in entityInsertions.keys {
                entityStates[id] = .managed
            }

            entityInsertions.removeAll()

            entityUpdates.removeAll()
            entityChangeSets.removeAll()

            for (id, entity) in entityDeletions {
                entityStates.removeValue(forKey: id)
                removeFromIdentityMap(entity: entity.entity, id: id)
            }

            entityDeletions.removeAll()
        }
    }

    func flush<E: Entity>(_ entity: E) async throws {
        // TODO: implement
    }

    func getRepository<R: Repository>(_ repositoryType: R.Type) -> R {
        let entityType = String(describing: repositoryType.E)

        if let repository = repositories[entityType] {
            return repository.repository as! R
        }

        let repository = R()
        repositories[entityType] = AnyRepository(repository)

        return repository
    }

    func merge<E: Entity>(_ entity: E) {
        // TODO: implement
    }

    func persist<E: Entity>(_ entity: inout E) throws {
        var entities = [AnyHashable: AnyEntity]()
        try persist(&entity, visited: &entities)
    }

    private func persist<E: Entity>(_ entity: inout E, visited entities: inout [AnyHashable: AnyEntity]) throws {
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
        entities[entityID] = AnyEntity(entity)
        let entityState = entityStates[entityID]

        switch entityState {
        case .detached: throw NSError()
        case .managed: break
        case .new:
            entityInsertions[entityID] = AnyEntity(entity)
            addToIdentityMap(entity)
        case .removed:
            entityDeletions.removeValue(forKey: entityID)
            addToIdentityMap(entity)
            entityStates[entityID] = .managed
        default:
            entityInsertions[entityID] = AnyEntity(entity)
            addToIdentityMap(entity)
            entityStates[entityID] = .new
        }
    }

    func refresh<E: Entity>(_ entity: inout E) throws {
        var entities = [AnyHashable: AnyEntity]()
        try refresh(&entity, visited: &entities)
    }

    private func refresh<E: Entity>(_ entity: inout E, visited entities: inout [AnyHashable: AnyEntity]) throws {
        let entityID = entity.id
        guard entities[entityID] == nil else { return }
        entities[entityID] = AnyEntity(entity)
        let entityState = entityStates[entityID]

        switch entityState {
        case .detached:
            // TODO: implement
            break
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
        var entities = [AnyHashable: AnyEntity]()
        remove(entity, visited: &entities)
    }

    private func remove<E: Entity>(_ entity: E, visited entities: inout [AnyHashable: AnyEntity]) {
        let entityID = entity.id
        guard entities[entityID] == nil else { return }
        entities[entityID] = AnyEntity(entity)
        let entityState = entityStates[entityID]

        switch entityState {
        case .managed:
            entityDeletions[entityID] = AnyEntity(entity)
            entityStates[entityID] = .removed
        case .new:
            entityInsertions.removeValue(forKey: entityID)
            removeFromIdentityMap(entity)
            entityStates.removeValue(forKey: entityID)
        default: break
        }
    }

    private func addToIdentityMap<E: Entity>(_ entity: E) {
        let entityID = entity.id
        let entityName = String(describing: type(of: entity))

        if identityMap[entityName] == nil {
            identityMap[entityName] = [entityID: AnyEntity(entity)]
        } else {
            identityMap[entityName]?[entityID] = AnyEntity(entity)
        }
    }

    private func removeFromIdentityMap<E: Entity>(_ entity: E) {
        let entityID = entity.id
        let entityName = String(describing: type(of: entity))
        identityMap[entityName]?.removeValue(forKey: entityID)
    }

    private func removeFromIdentityMap(entity: Codable, id: AnyHashable) {
        let entityName = String(describing: type(of: entity))
        identityMap[entityName]?.removeValue(forKey: id)
    }
}

extension SQLEntityManager {
    enum EntityState {
        case detached
        case new
        case managed
        case removed
    }
}
