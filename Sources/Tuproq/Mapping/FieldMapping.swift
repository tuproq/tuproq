public struct FieldMapping: Hashable {
    public let name: String
    public let column: String
    public let type: Kind
    public let isUnique: Bool
    public let isNullable: Bool
    public let precision: UInt
    public let scale: UInt

    public init(
        name: String,
        column: String? = nil,
        type: Kind,
        isUnique: Bool = false,
        isNullable: Bool = false,
        precision: UInt = 0,
        scale: UInt = 0
    ) {
        self.name = name
        self.column = column ?? name
        self.type = type
        self.isUnique = isUnique
        self.isNullable = isNullable
        self.precision = precision
        self.scale = scale
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name || lhs.column == rhs.column
    }
}

public extension FieldMapping {
    enum Kind: Hashable {
        case text
        case timestamptz
        case uuid
        case varchar(_ length: UInt? = nil)

        var value: String {
            switch self {
            case .text: return "text"
            case .timestamptz: return "timestamptz"
            case .uuid: return "uuid"
            case .varchar(let length):
                let value = "varchar"

                if let length = length {
                    return "\(value)(\(length))"
                }

                return value
            }
        }
    }
}
