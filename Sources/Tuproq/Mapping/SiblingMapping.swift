public struct SiblingMapping: AssociationMapping {
    public let field: String
    let entity: Any
    public let joinTable: JoinTable?

    public init<E: Entity>(
        field: String,
        entity: E.Type,
        joinTable: JoinTable? = nil
    ) {
        self.field = field
        self.entity = entity
        self.joinTable = joinTable
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.field == rhs.field
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(field)
    }
}
