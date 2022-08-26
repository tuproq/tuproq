public struct FieldMapping: Hashable {
    public let name: String
    public let column: String
    public let type: Kind
    public let isUnique: Bool
    public let isNullable: Bool

    public init(
        name: String,
        type: Kind,
        column: String? = nil,
        isUnique: Bool = false,
        isNullable: Bool = false
    ) {
        self.name = name
        self.type = type
        self.column = column ?? name
        self.isUnique = isUnique
        self.isNullable = isNullable
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name || lhs.column == rhs.column
    }
}

public extension FieldMapping {
    enum Kind: Hashable {
        case bool
        case character
        case data(length: UInt? = nil, isFixed: Bool = false)
        case date
        case decimal(precision: UInt, scale: UInt, isUnsigned: Bool = false)
        case double(isUnsigned: Bool = false)
        case float(isUnsigned: Bool = false)
        case int8
        case int16
        case int32
        case int64
        case string(length: UInt? = nil, isFixed: Bool = false)
        case uint8
        case uint16
        case uint32
        case uint64
        case uuid
    }
}
