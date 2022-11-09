public struct IDMapping: Hashable {
    public let field: String
    public let type: FieldType
    public let column: String

    public init(field: String = "id", type: FieldType = .id(), column: String) {
        self.field = field
        self.type = type
        self.column = column
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.field == rhs.field
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(field)
    }
}
