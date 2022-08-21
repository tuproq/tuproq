public struct FieldMapping: Hashable {
    public let name: String
    public let column: String
    public let type: Kind
    public let length: UInt
    public let isUnique: Bool
    public let isNullable: Bool
    public let precision: UInt
    public let scale: UInt

    public init(
        name: String,
        column: String? = nil,
        type: Kind,
        length: UInt = 255,
        isUnique: Bool = false,
        isNullable: Bool = false,
        precision: UInt = 0,
        scale: UInt = 0
    ) {
        self.name = name
        self.column = column ?? name
        self.type = type
        self.length = length
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
    enum Kind: String {
        case timestamptz
        case uuid
        case varchar
    }
}
