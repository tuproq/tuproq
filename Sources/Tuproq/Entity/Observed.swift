import Foundation

@propertyWrapper
public final class Observed<V: Codable>: Codable {
    private var entityID: AnyHashable?
    private var entityName: String?
    private var entityManager: (any EntityManager)?
    private var name: String?
    private var value: V

    @available(*, unavailable, message: "@Observed can only be applied to classes.")
    public var wrappedValue: V {
        get { fatalError() }
        set { fatalError() }
    }

    public init(wrappedValue: V) {
        value = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        entityName = decoder.userInfo[.entityName] as? String
        entityID = decoder.userInfo[.entityID] as? AnyHashable
        entityManager = decoder.userInfo[.entityManager] as? (any EntityManager)
        name = decoder.codingPath.last?.stringValue
        value = try decoder.singleValueContainer().decode(V.self)
        addPropertyObserver()
    }

    deinit {
        removePropertyObserver()
    }

    public static subscript<E: Entity>(
        _enclosingInstance entity: E,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<E, V>,
        storage storageKeyPath: ReferenceWritableKeyPath<E, Observed>
    ) -> V {
        get {
            entity[keyPath: storageKeyPath].value
        }
        set {
            guard let name = entity[keyPath: storageKeyPath].name else { return }
            entity[keyPath: storageKeyPath].entityName = Configuration.entityName(from: entity)
            let oldValue = entity[keyPath: storageKeyPath].value
            entity[keyPath: storageKeyPath].value = newValue
            entity[keyPath: storageKeyPath].entityManager?.propertyChanged(
                entity: entity,
                propertyName: name,
                oldValue: oldValue,
                newValue: newValue
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }

    private func addPropertyObserver() {
        NotificationCenter.default.addObserver(
            forName: .propertyPostFlushValueChanged,
            object: nil,
            queue: nil
        ) { [self] notification in
            let dictionary = notification.object as! [String: Any?]
            let entity = dictionary["entity"] as! String
            let oldID = dictionary["oldID"] as! AnyHashable
            var newID = dictionary["newID"] as! AnyHashable
            let property = dictionary["property"] as! [String: Any?]
            let propertyName = property["name"] as! String
            var propertyValue = property["value"]

            if let uuid = newID as? UUID { // TODO: check if the field type is UUID
                newID = AnyHashable(uuid.uuidString)
            }

            if let uuid = propertyValue as? UUID { // TODO: check if the field type is UUID
                propertyValue = uuid.uuidString
            }

            if entity == entityName && oldID == entityID && propertyName == name {
                if let propertyValue = propertyValue as? V { // TODO: check if Field is nullable or not.
                    value = propertyValue
                }

                entityID = newID

                if name == "id" {
                    value = entityID as! V
                }
            }
        }
    }

    private func removePropertyObserver() {
        NotificationCenter.default.removeObserver(self, name: .propertyPostFlushValueChanged, object: nil)
    }
}
