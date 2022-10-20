public struct ParentMapping<Source: Entity>: AssociationMapping {
    public let field: PartialKeyPath<Source>
    let entity: AnyEntity.Type
    public let column: JoinTable.Column

    public init<Target: Entity>(field: PartialKeyPath<Source>, entity: Target.Type, column: JoinTable.Column) {
        self.field = field
        self.entity = entity
        self.column = column
    }
}
