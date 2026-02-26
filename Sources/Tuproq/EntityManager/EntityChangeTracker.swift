import Foundation

final class EntityChangeTracker: Locking, @unchecked Sendable {
    typealias ChangeSet = [String: (oldValue: Codable?, newValue: Codable?)]
    typealias EntityMap = [ObjectID: any Entity]
    typealias ObjectID = ObjectIdentifier

    let lock = NSLock()

    private var insertions = EntityMap()
    private var updates = EntityMap()
    private var removals = EntityMap()

    private var changeSets = [ObjectID: ChangeSet]()
    private var identityMap = [String: EntityMap]()
    private var idsMap = [ObjectID: EntityID]()
    private var objectIDsMap = [EntityID: ObjectID]()
    private var statesMap = [ObjectID: EntityState]()

    init() {}

    func cleanUpDirty() {
        withLock {
            for objectID in insertions.keys {
                statesMap[objectID] = .managed
            }

            for entity in removals.values {
                removeFromIdentityMap(entity)
            }

            insertions.removeAll()
            updates.removeAll()
            removals.removeAll()
            changeSets.removeAll()
        }
    }
}

// MARK: - ChangeSet

extension EntityChangeTracker {
    func changeSet(for objectID: ObjectID) -> ChangeSet? {
        withLock { changeSets[objectID] }
    }
}

// MARK: - Entity

extension EntityChangeTracker {
    struct EntityID: Codable, Hashable {
        let value: AnyHashable

        init(_ value: AnyHashable) {
            self.value = value
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let stringValue = try container.decode(String.self)
            value = AnyHashable(stringValue)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(String(describing: value))
        }
    }

    func entity<E: Entity>(_ entityType: E.Type, id: E.ID) -> E? {
        withLock {
            let entityName = Configuration.entityName(from: entityType)

            if let objectID = objectIDsMap[.init(id)],
               let entity = identityMap[entityName]?[objectID] as? E {
                return entity
            }

            return nil
        }
    }

    func id(for objectID: ObjectID) -> EntityID? {
        withLock { idsMap[objectID] }
    }
}

// MARK: - EntityMap

extension EntityChangeTracker {
    func insert<E: Entity>(_ entity: E) {
        withLock {
            let objectID = ObjectIdentifier(entity)
            insertIntoIdentityMap(entity)
            statesMap[objectID] = .managed
        }
    }

    func insertNew<E: Entity>(_ entity: inout E) throws {
        let shouldInsert = withLock {
            let objectID = ObjectID(entity)

            if let state = statesMap[objectID] {
                if state == .removed {
                    removals.removeValue(forKey: objectID)
                    statesMap[objectID] = .managed
                }

                return false
            }

            statesMap[objectID] = .initializing

            return true
        }

        guard shouldInsert else { return }

        do {
            try encodeDecode(&entity)
        } catch {
            withLock {
                let objectID = ObjectID(entity)

                if statesMap[objectID] == .initializing {
                    statesMap.removeValue(forKey: objectID)
                }
            }

            throw error
        }

        withLock {
            let objectID = ObjectID(entity)
            insertIntoIdentityMap(entity)
            statesMap[objectID] = .new
            insertions[objectID] = entity
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
            case .new: removeFromIdentityMap(entity)
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
    private func insertIntoIdentityMap<E: Entity>(_ entity: E) {
        let entityName = Configuration.entityName(from: entity)
        let objectID = ObjectID(entity)
        identityMap[entityName, default: .init()][objectID] = entity
        idsMap[objectID] = .init(entity.id)
        objectIDsMap[.init(entity.id)] = objectID
    }

    private func removeFromIdentityMap<E: Entity>(_ entity: E) {
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
        _ property: String,
        entity: E,
        oldValue: Codable?,
        newValue: Codable?
    ) {
        withLock {
            let entityName = Configuration.entityName(from: entity)
            let objectID = ObjectID(entity)
            guard identityMap[entityName]?[objectID] != nil else { return }
            updates[objectID] = entity
            var changeSet = changeSets[objectID, default: .init()]
            changeSet[property] = (oldValue, newValue)
            changeSets[objectID] = changeSet
        }
    }
}

// MARK: - Decoder/Encoder

extension EntityChangeTracker {
    func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.userInfo = [.entityChangeTracker: self]

        return decoder
    }

    private func createEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        return encoder
    }

    func dictionary<E: Entity>(from entity: E) throws -> [String: Any?] {
        try withLock { try _dictionary(from: entity) }
    }

    private func _dictionary<E: Entity>(from entity: E) throws -> [String: Any?] {
        let encoder = createEncoder()
        guard let dictionary = try JSONSerialization.jsonObject(
            with: try encoder.encode(entity),
            options: .fragmentsAllowed
        ) as? [String: Any?] else { throw error(.entityToDictionaryFailed) }

        return dictionary
    }

    func encodeValue(_ value: (any Codable)?) throws -> Any? {
        try withLock {
            guard let value else { return nil }
            let encoder = createEncoder()

            return try JSONSerialization.jsonObject(
                with: try encoder.encode(value),
                options: .fragmentsAllowed
            )
        }
    }

    private func encodeDecode<E: Entity>(_ entity: inout E) throws {
        let dictionary = try _dictionary(from: entity)
        let data = try JSONSerialization.data(withJSONObject: dictionary)

        let decoder = createDecoder()
        entity = try decoder.decode(E.self, from: data)
    }
}
