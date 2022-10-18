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
}
