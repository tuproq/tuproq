import Foundation

extension Entity {
    public typealias Field<V: Codable> = FieldProperty<Self, V>
}

@propertyWrapper
public struct FieldProperty<E: Entity, V: Codable>: Codable {
    public let name: String
    public let type: `Type`
    private var entityID: AnyHashable?
    private var value: V!
    private var isInit = true

    public var wrappedValue: V {
        get { return value }
        set {
            let oldValue = value
            value = newValue

            if isInit {
                isInit = false
            } else {
                if let entityID = entityID {
                    let property: [String: Any?] = [
                        "name": name,
                        "oldValue": oldValue,
                        "newValue": value
                    ]
                    let dictionary: [String: Any?] = [
                        "entityName": String(describing: E.self),
                        "id": entityID,
                        "property": property
                    ]
                    NotificationCenter.default.post(name: propertyValueChanged, object: dictionary)
                }
            }
        }
    }

    public init(name: String) {
        self.name = name
        type = .string // TODO: set the default type based on the type of value
    }

    public init(name: String, type: `Type`) {
        self.name = name
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        entityID = decoder.userInfo[CodingUserInfoKey(rawValue: "id")!] as? AnyHashable

        if let name = decoder.codingPath.first?.stringValue {
            self.name = name
        } else {
            name = "" // TODO: throw error
        }

        type = .string // TODO: set the type based on the type of value

        let container = try decoder.singleValueContainer()
        wrappedValue = try container.decode(V.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

extension FieldProperty {
    public enum `Type`: String {
        case boolean
        case character
        case date
        case double
        case float
        case int
        case string
        case uuid
    }
}
