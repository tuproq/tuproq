public struct SiblingMapping<Source: Entity>: AssociationMapping {
    public let field: PartialKeyPath<Source>
    let entity: AnyEntity.Type
    let mappedBy: AnyKeyPath?
    let inversedBy: AnyKeyPath?
    public let joinTable: JoinTable?

    public init<Target: Entity>(
        field: PartialKeyPath<Source>,
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
