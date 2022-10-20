public struct ParentMapping<Source: Entity>: AssociationMapping {
    public let field: PartialKeyPath<Source>
    let entity: AnyEntity.Type
    let inversedBy: AnyKeyPath?
    public let column: JoinTable.Column

    public init<Target: Entity>(
        field: PartialKeyPath<Source>,
        entity: Target.Type,
        inversedBy: PartialKeyPath<Target>? = nil,
        column: JoinTable.Column
    ) {
        self.field = field
        self.entity = entity
        self.inversedBy = inversedBy
        self.column = column
    }
}
