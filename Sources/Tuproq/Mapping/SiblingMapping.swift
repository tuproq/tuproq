public struct SiblingMapping: AssociationMapping {
    public let field: String
    let entity: AnyEntity.Type
    let mappedBy: AnyKeyPath?
    let inversedBy: AnyKeyPath?
    public let joinTable: JoinTable?

    public init<Target: Entity>(
        field: String,
        entity: Target.Type,
        mappedBy: PartialKeyPath<Target>? = nil,
        inversedBy: PartialKeyPath<Target>? = nil,
        joinTable: JoinTable? = nil
    ) {
        self.field = field
        self.entity = entity
        self.mappedBy = mappedBy
        self.inversedBy = inversedBy
        self.joinTable = joinTable
    }
}
