public struct ParentMapping: AssociationMapping {
    public let field: String
    public let entity: any Entity.Type
    public let inversedBy: String?
    public let column: JoinTable.Column

    public init<Target: Entity>(
        field: String,
        entity: Target.Type,
        inversedBy: String? = nil,
        column: JoinTable.Column
    ) {
        self.field = field
        self.entity = entity
        self.inversedBy = inversedBy
        self.column = column
    }
}
