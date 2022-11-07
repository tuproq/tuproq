public struct ChildMapping: AssociationMapping {
    public let field: String
    let entity: AnyEntity.Type
    let mappedBy: AnyKeyPath?

    public init<Target: Entity>(
        field: String,
        entity: Target.Type,
        mappedBy: PartialKeyPath<Target>? = nil
    ) {
        self.field = field
        self.entity = entity
        self.mappedBy = mappedBy
    }
}
