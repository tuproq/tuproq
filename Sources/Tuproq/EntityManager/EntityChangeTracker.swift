import Foundation

final class EntityChangeTracker: @unchecked Sendable {
    typealias ChangeSet = [String: (oldValue: Codable?, newValue: Codable?)]
    private typealias EntityChanges = [String: EntityMap]
    private typealias EntityChangeSets = [ObjectIdentifier: ChangeSet]
    typealias EntityMap = [ObjectIdentifier: any Entity]
    private typealias EntityStates = [ObjectIdentifier: EntityState]

    private let encoder: JSONEncoder
    let decoder: JSONDecoder
    private let lock = NSLock()

    private var entityInsertions = EntityMap()
    private var entityUpdates = EntityMap()
    private var entityDeletions = EntityMap()
    private var entityStates = EntityStates()
    private var entityChangeSets = EntityChangeSets()
    private var identityMap = EntityChanges()
    private var entityIdentifiers = [ObjectIdentifier: AnyHashable]()
    private var objectIdentifiers = [AnyHashable: ObjectIdentifier]()

    init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.userInfo = [.entityChangeTracker: self]
    }

    func propertyValueChanged<E: Entity>(
        _ entity: E,
        name: String,
        oldValue: Codable?,
        newValue: Codable?
    ) {
        withLock {
            let entityName = Configuration.entityName(from: entity)
            let objectID = ObjectIdentifier(entity)
            guard identityMap[entityName]?[objectID] != nil else { return }
            entityUpdates[objectID] = entity
            var changeSet = entityChangeSets[objectID, default: .init()]
            changeSet[name] = (oldValue, newValue)
            entityChangeSets[objectID] = changeSet
        }
    }

    func addEntityToIdentityMap<E: Entity>(_ entity: E) {
        withLock {
            let entityName = Configuration.entityName(from: entity)
            let objectID = ObjectIdentifier(entity)
            identityMap[entityName, default: .init()][objectID] = entity
            entityIdentifiers[objectID] = entity.id
            objectIdentifiers[entity.id] = objectID
        }
    }

    func getEntityToIdentityMap<E: Entity>(_ entityType: E.Type, id: E.ID) -> E? {
        withLock {
            let entityName = Configuration.entityName(from: entityType)

            if let objectID = objectIdentifiers[id], let entity = identityMap[entityName]?[objectID] as? E {
                return entity
            }

            return nil
        }
    }

    func removeEntityFromIdentityMap<E: Entity>(_ entity: E) {
        withLock {
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

    func cleanUpDirty() {
        withLock {
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
        }
    }

    func getEntityChangeSet(id: ObjectIdentifier) -> ChangeSet? {
        withLock { entityChangeSets[id] }
    }

    func getEntityState(id: ObjectIdentifier) -> EntityState? {
        withLock { entityStates[id] }
    }

    func setEntityState(
        _ state: EntityState,
        id: ObjectIdentifier
    ) {
        withLock { entityStates[id] = state }
    }

    func getInsertedEntities() -> EntityMap {
        withLock { entityInsertions }
    }

    func insertEntity<E: Entity>(_ entity: inout E) throws {
        try withLock {
            let objectID = ObjectIdentifier(entity)

            if let state = getEntityState(id: objectID) {
                if state == .removed {
                    entityDeletions.removeValue(forKey: objectID)
                    entityStates[objectID] = .managed
                }
            } else {
                try register(&entity)
                let objectID = ObjectIdentifier(entity)
                addEntityToIdentityMap(entity)
                entityStates[objectID] = .new
                entityInsertions[objectID] = entity
            }
        }
    }

    func getUpdatedEntities() -> EntityMap {
        withLock { entityUpdates }
    }

    func getDeletedEntities() -> EntityMap {
        withLock { entityDeletions }
    }

    func getEntityIdentifier(objectID: ObjectIdentifier) -> AnyHashable? {
        withLock { entityIdentifiers[objectID] }
    }

    func removeEntity<E: Entity>(_ entity: E) {
        withLock {
            let objectID = ObjectIdentifier(entity)
            guard let state = entityStates[objectID] else { return }
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

extension EntityChangeTracker {
    private func register<E: Entity>(_ entity: inout E) throws {
        let dictionary = try encodeToDictionary(entity)
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        entity = try decoder.decode(E.self, from: data)
    }

    func encodeToDictionary<E: Entity>(_ entity: E) throws -> [String: Any?] {
        guard let dictionary = try JSONSerialization.jsonObject(
            with: try encoder.encode(entity),
            options: .fragmentsAllowed
        ) as? [String: Any?] else { throw error(.entityToDictionaryFailed) }
        return dictionary
    }

    func encodeValue(_ value: (any Codable)?) throws -> Any? {
        guard let value else { return nil }
        return try JSONSerialization.jsonObject(
            with: try encoder.encode(value),
            options: .fragmentsAllowed
        )
    }
}

extension EntityChangeTracker {
    @inline(__always)
    private func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }

        return try body()
    }
}
