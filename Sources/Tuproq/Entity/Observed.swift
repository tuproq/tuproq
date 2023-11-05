import Foundation

@propertyWrapper
public final class Observed<V: Codable>: Codable {
    private var name: String?
    private var entityID: AnyHashable?
    private var entityName: String?
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
        entityName = decoder.userInfo[CodingUserInfoKey(rawValue: "entityName")!] as? String
        entityID = decoder.userInfo[CodingUserInfoKey(rawValue: "entityID")!] as? AnyHashable

        if let name = decoder.codingPath.first?.stringValue, !name.isEmpty {
            self.name = name
        } else {
            name = "" // TODO: throw error
        }

        let container = try decoder.singleValueContainer()
        value = try container.decode(V.self)
        addPropertyObserver()
    }

    deinit {
        removePropertyObserver()
    }

    public static subscript<E: Entity>(
        _enclosingInstance instance: E,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<E, V>,
        storage storageKeyPath: ReferenceWritableKeyPath<E, Observed>
    ) -> V {
        get {
            instance[keyPath: storageKeyPath].value
        }
        set {
            let entityName = Configuration.entityName(from: instance)
            instance[keyPath: storageKeyPath].entityName = entityName
            let oldValue = instance[keyPath: storageKeyPath].value
            instance[keyPath: storageKeyPath].value = newValue
            let id = instance.id

            if let name = instance[keyPath: storageKeyPath].name {
                let property: [String: Any?] = [
                    "name": name,
                    "oldValue": oldValue,
                    "newValue": instance[keyPath: storageKeyPath].value
                ]
                let dictionary: [String: Any?] = [
                    "entity": entityName,
                    "id": id,
                    "property": property
                ]
                NotificationCenter.default.post(name: propertyValueChanged, object: dictionary)
            }
        }
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
        NotificationCenter.default.removeObserver(self, name: propertyPostFlushValueChanged, object: nil)
    }
}
