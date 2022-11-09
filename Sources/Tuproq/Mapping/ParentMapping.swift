public struct ParentMapping: AssociationMapping {
    public let field: String
    let entity: any Entity.Type
    let inversedBy: AnyKeyPath?
    public let column: JoinTable.Column

    public init<Target: Entity>(
        field: String,
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
