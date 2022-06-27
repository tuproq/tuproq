import Foundation

extension Entity {
    public typealias Field<V: Codable> = FieldProperty<Self, V>
}

@propertyWrapper
public class FieldProperty<E: Entity, V: Codable>: Codable {
    public let name: String
    public let type: `Type`
    private var entityID: AnyHashable?
    private var value: V!
    private var isInit = true

    public var wrappedValue: V {
        get { value }
        set {
            let oldValue = value
            value = newValue

            if isInit {
                isInit = false
            } else {
                if let id = entityID {
                    let property: [String: Any?] = [
                        "name": name,
                        "oldValue": oldValue,
                        "newValue": value
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
    }

    public init(name: String = "") {
        self.name = name
        let valueType = V.Type.self

        if valueType == Bool.Type.self {
            type = .bool
        } else if valueType == Character.Type.self {
            type = .character
        } else if valueType == Date.Type.self {
            type = .date
        } else if valueType == Double.Type.self {
            type = .double
        } else if valueType == Float.Type.self {
            type = .float
        } else if valueType == Int.Type.self {
            type = .int
        } else if valueType == String.Type.self {
            type = .string
        } else if valueType == UUID.Type.self {
            type = .uuid
        } else {
            type = .string
        }

        addPropertyObserver()
    }

    public init(name: String = "", type: `Type`) {
        self.name = name
        self.type = type // TODO: check if type is supported and matches the value type
        addPropertyObserver()
    }

    public required init(from decoder: Decoder) throws {
        entityID = decoder.userInfo[CodingUserInfoKey(rawValue: "id")!] as? AnyHashable

        if let name = decoder.codingPath.first?.stringValue {
            self.name = name
        } else {
            name = "" // TODO: throw error
        }

        type = .string // TODO: set the type based on the type of value

        let container = try decoder.singleValueContainer()
        wrappedValue = try container.decode(V.self)
        addPropertyObserver()
    }

    deinit {
        removePropertyObserver()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
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

            if entity == E.entity && id == entityID && propertyName == name {
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

extension FieldProperty {
    public enum `Type`: String {
        case bool
        case character
        case date
        case double
        case float
        case int
        case string
        case uuid
    }
}
