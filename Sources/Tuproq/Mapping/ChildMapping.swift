public struct ChildMapping<Source: Entity>: AssociationMapping {
    public let field: PartialKeyPath<Source>
    let entity: AnyEntity.Type
    let mappedBy: AnyKeyPath?

    public init<Target: Entity>(
        field: PartialKeyPath<Source>,
        entity: Target.Type,
        mappedBy: PartialKeyPath<Target>? = nil
    ) {
        self.field = field
        self.entity = entity
        self.mappedBy = mappedBy
    }
}
