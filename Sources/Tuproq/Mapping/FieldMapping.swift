public struct FieldMapping: Hashable {
    public let name: String
    public let type: FieldType
    public let column: String
    public let isUnique: Bool
    public let isNullable: Bool

    public init(
        name: String,
        type: FieldType,
        column: String? = nil,
        isUnique: Bool = false,
        isNullable: Bool = true
    ) {
        self.name = name
        self.type = type
        self.column = column ?? name
        self.isUnique = isUnique
        self.isNullable = isNullable
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
