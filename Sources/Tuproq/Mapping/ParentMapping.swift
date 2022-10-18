public struct ParentMapping: AssociationMapping {
    public let field: String
    let entity: Any
    public let column: JoinTable.Column

    public init<E: Entity>(
        field: String,
        entity: E.Type,
        column: JoinTable.Column? = nil
    ) {
        self.field = field
        self.entity = entity
        self.column = column ?? .init(name: TuproqORM.namingStrategy.joinColumn(field: field))
    }
}
