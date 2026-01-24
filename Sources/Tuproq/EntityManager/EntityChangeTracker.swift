import Foundation

final class EntityChangeTracker: @unchecked Sendable {
    typealias ChangeSet = [String: (oldValue: Codable?, newValue: Codable?)]
    typealias EntityMap = [ObjectID: any Entity]
    typealias ID = AnyHashable
    typealias ObjectID = ObjectIdentifier

    private let encoder: JSONEncoder
    let decoder: JSONDecoder
    private let lock = NSLock()

    private var insertions = EntityMap()
    private var updates = EntityMap()
    private var removals = EntityMap()

    private var changeSets = [ObjectID: ChangeSet]()
    private var identityMap = [String: EntityMap]()
    private var idsMap = [ObjectID: ID]()
    private var objectIDsMap = [ID: ObjectID]()
    private var statesMap = [ObjectID: EntityState]()

    init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.userInfo = [.entityChangeTracker: self]
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

    func getChangeSet(for objectID: ObjectID) -> ChangeSet? {
        withLock { changeSets[objectID] }
    }

    func setState(
        _ state: EntityState,
        for objectID: ObjectID
    ) {
        withLock { statesMap[objectID] = state }
    }

    func getID(for objectID: ObjectID) -> ID? {
        withLock { idsMap[objectID] }
    }
}

// MARK: - EntityMap

extension EntityChangeTracker {
    func insert<E: Entity>(_ entity: inout E) throws {
        try withLock {
            let objectID = ObjectID(entity)

            if let state = statesMap[objectID] {
                if state == .removed {
                    removals.removeValue(forKey: objectID)
                    statesMap[objectID] = .managed
                }
            } else {
                try register(&entity)
                let objectID = ObjectID(entity)
                _addEntityToIdentityMap(entity)
                statesMap[objectID] = .new
                insertions[objectID] = entity
            }
        }
    }

    func remove<E: Entity>(_ entity: E) {
        withLock {
            let objectID = ObjectID(entity)
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

    func getInsertions() -> EntityMap {
        withLock { insertions }
    }

    func getUpdates() -> EntityMap {
        withLock { updates }
    }

    func getRemovals() -> EntityMap {
        withLock { removals }
    }
}

// MARK: - IdentityMap

extension EntityChangeTracker {
    func addEntityToIdentityMap<E: Entity>(_ entity: E) {
        withLock { _addEntityToIdentityMap(entity) }
    }

    private func _addEntityToIdentityMap<E: Entity>(_ entity: E) {
        let entityName = Configuration.entityName(from: entity)
        let objectID = ObjectID(entity)
        identityMap[entityName, default: .init()][objectID] = entity
        idsMap[objectID] = entity.id
        objectIDsMap[entity.id] = objectID
    }

    func getEntityFromIdentityMap<E: Entity>(_ entityType: E.Type, id: E.ID) -> E? {
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
        let objectID = ObjectID(entity)

        if let id = idsMap[objectID] {
            objectIDsMap.removeValue(forKey: id)
        }

        insertions.removeValue(forKey: objectID)
        updates.removeValue(forKey: objectID)
        removals.removeValue(forKey: objectID)
        changeSets.removeValue(forKey: objectID)
        idsMap.removeValue(forKey: objectID)
        statesMap.removeValue(forKey: objectID)

        let entityName = Configuration.entityName(from: entity)
        identityMap[entityName]?.removeValue(forKey: objectID)

        if let entityMap = identityMap[entityName], entityMap.isEmpty {
            identityMap.removeValue(forKey: entityName)
        }
    }
}

// MARK: - Property

extension EntityChangeTracker {
    func updateProperty<E: Entity>(
        _ entity: E,
        name: String,
        oldValue: Codable?,
        newValue: Codable?
    ) {
        withLock {
            let entityName = Configuration.entityName(from: entity)
            let objectID = ObjectID(entity)
            guard identityMap[entityName]?[objectID] != nil else { return }
            updates[objectID] = entity
            var changeSet = changeSets[objectID, default: .init()]
            changeSet[name] = (oldValue, newValue)
            changeSets[objectID] = changeSet
        }
    }
}

// MARK: -

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

// MARK: -

extension EntityChangeTracker {
    @inline(__always)
    private func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }

        return try body()
    }
}
