import Foundation

@propertyWrapper
public final class Persisted<V: Codable>: Codable {
    private var name: String?
    private var entityID: AnyHashable?
    private var entityName: String?
    private var value: V

    public static subscript<E: Entity>(
        _enclosingInstance instance: E,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<E, V>,
        storage storageKeyPath: ReferenceWritableKeyPath<E, Persisted>
    ) -> V {
        get {
            instance[keyPath: storageKeyPath].value
        }
        set {
            instance[keyPath: storageKeyPath].entityName = E.entity
            let oldValue = instance[keyPath: storageKeyPath].value
            instance[keyPath: storageKeyPath].value = newValue

            if let id = instance[keyPath: storageKeyPath].entityID,
               let name = instance[keyPath: storageKeyPath].name {
                let property: [String: Any?] = [
                    "name": name,
                    "oldValue": oldValue,
                    "newValue": instance[keyPath: storageKeyPath].value
                ]
                let dictionary: [String: Any?] = [
                    "entity": E.entity,
                    "id": id,
                    "property": property
                ]
                NotificationCenter.default.post(name: propertyValueChanged, object: dictionary)
            }
        }
    }

    @available(*, unavailable, message: "@Persisted can only be applied to classes.")
    public var wrappedValue: V {
        get { fatalError() }
        set { fatalError() }
    }

    public init(wrappedValue: V) {
        value = wrappedValue
        addPropertyObserver()
    }

    deinit {
        removePropertyObserver()
    }

    public init(from decoder: Decoder) throws {
        entityID = decoder.userInfo[CodingUserInfoKey(rawValue: "id")!] as? AnyHashable

        if let name = decoder.codingPath.first?.stringValue, !name.isEmpty {
            self.name = name
        } else {
            name = "" // TODO: throw error
        }

        let container = try decoder.singleValueContainer()
        value = try container.decode(V.self)
        addPropertyObserver()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }

    private func addPropertyObserver() {
        NotificationCenter.default.addObserver(
            forName: propertyPostFlushValueChanged,
            object: nil,
            queue: nil
        ) { [self] notification in
            let dictionary = notification.object as! [String: Any?]
            let entity = dictionary["entity"] as! String
            var id = dictionary["id"] as! AnyHashable
            let property = dictionary["property"] as! [String: Any?]
            let propertyName = property["name"] as! String
            var propertyValue = property["value"]

            if let uuid = id as? UUID { // TODO: check if the field type is UUID
                id = AnyHashable(uuid.uuidString)
            }

            if let uuid = propertyValue as? UUID { // TODO: check if the field type is UUID
                propertyValue = uuid.uuidString
            }

            if entity == entityName && id == entityID && propertyName == name {
                if let propertyValue = propertyValue as? V { // TODO: check if Field is nullable or not.
                    value = propertyValue
                }

                if name == "id" {
                    entityID = propertyValue as? AnyHashable
                }
            }
        }
    }

    private func removePropertyObserver() {
        NotificationCenter.default.removeObserver(self, name: propertyPostFlushValueChanged, object: nil)
    }
}
