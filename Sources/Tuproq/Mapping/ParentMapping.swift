public struct ParentMapping: Hashable {
    public let field: String
    let entity: Any
    public let column: String
    public let isUnique: Bool
    public let isNullable: Bool

    public init<E: Entity>(
        field: String,
        entity: E.Type,
        column: String? = nil,
        isUnique: Bool = false,
        isNullable: Bool = false
    ) {
        self.field = field
        self.entity = entity
        self.column = column ?? field
        self.isUnique = isUnique
        self.isNullable = isNullable
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.field == rhs.field
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(field)
    }
}
