import Foundation

final class EntityChangeTracker: @unchecked Sendable {
    typealias ChangeSet = [String: (oldValue: Codable?, newValue: Codable?)]
    typealias EntityMap = [ObjectIdentifier: any Entity]

    private let encoder: JSONEncoder
    let decoder: JSONDecoder
    private let lock = NSLock()

    private var changeSets = [ObjectIdentifier: ChangeSet]()
    private var identityMap = [String: EntityMap]()
    private var idsMap = [ObjectIdentifier: AnyHashable]()
    private var objectIDsMap = [AnyHashable: ObjectIdentifier]()
    private var statesMap = [ObjectIdentifier: EntityState]()

    private var insertions = EntityMap()
    private var updates = EntityMap()
    private var removals = EntityMap()

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
            updates[objectID] = entity
            var changeSet = changeSets[objectID, default: .init()]
            changeSet[name] = (oldValue, newValue)
            changeSets[objectID] = changeSet
        }
    }

    func addEntityToIdentityMap<E: Entity>(_ entity: E) {
        withLock {
            let entityName = Configuration.entityName(from: entity)
            let objectID = ObjectIdentifier(entity)
            identityMap[entityName, default: .init()][objectID] = entity
            idsMap[objectID] = entity.id
            objectIDsMap[entity.id] = objectID
        }
    }

    func getEntityIdentityMap<E: Entity>(_ entityType: E.Type, id: E.ID) -> E? {
        withLock {
            let entityName = Configuration.entityName(from: entityType)

            if let objectID = objectIDsMap[id],
               let entity = identityMap[entityName]?[objectID] as? E {
                return entity
            }

            return nil
        }
    }

    private func removeEntityFromIdentityMap<E: Entity>(_ entity: E) {
        let objectID = ObjectIdentifier(entity)

        if let id = idsMap[objectID] {
            objectIDsMap.removeValue(forKey: id)
        }

        idsMap.removeValue(forKey: objectID)
        insertions.removeValue(forKey: objectID)
        updates.removeValue(forKey: objectID)
        removals.removeValue(forKey: objectID)
        changeSets.removeValue(forKey: objectID)
        statesMap.removeValue(forKey: objectID)

        let entityName = Configuration.entityName(from: entity)
        identityMap[entityName]?.removeValue(forKey: objectID)

        if let entityMap = identityMap[entityName], entityMap.isEmpty {
            identityMap.removeValue(forKey: entityName)
        }
    }

    func cleanUpDirty() {
        withLock {
            for objectID in insertions.keys {
                statesMap[objectID] = .managed
            }

            for entity in removals.values {
                removeEntityFromIdentityMap(entity)
            }

            insertions.removeAll()
            updates.removeAll()
            removals.removeAll()
            changeSets.removeAll()
        }
    }

    func getEntityChangeSet(objectID: ObjectIdentifier) -> ChangeSet? {
        withLock { changeSets[objectID] }
    }

    func setEntityState(
        _ state: EntityState,
        id: ObjectIdentifier
    ) {
        withLock { statesMap[id] = state }
    }

    func getInsertedEntities() -> EntityMap {
        withLock { insertions }
    }

    func getUpdatedEntities() -> EntityMap {
        withLock { updates }
    }

    func getDeletedEntities() -> EntityMap {
        withLock { removals }
    }

    func getEntityIdentifier(objectID: ObjectIdentifier) -> AnyHashable? {
        withLock { idsMap[objectID] }
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
    func insertEntity<E: Entity>(_ entity: inout E) throws {
        try withLock {
            let objectID = ObjectIdentifier(entity)

            if let state = statesMap[objectID] {
                if state == .removed {
                    removals.removeValue(forKey: objectID)
                    statesMap[objectID] = .managed
                }
            } else {
                try register(&entity)
                let objectID = ObjectIdentifier(entity)
                addEntityToIdentityMap(entity)
                statesMap[objectID] = .new
                insertions[objectID] = entity
            }
        }
    }

    func removeEntity<E: Entity>(_ entity: E) {
        withLock {
            let objectID = ObjectIdentifier(entity)
            guard let state = statesMap[objectID] else { return }

            switch state {
            case .managed:
                removals[objectID] = entity
                statesMap[objectID] = .removed
            case .new: removeEntityFromIdentityMap(entity)
            default: break
            }
        }
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
