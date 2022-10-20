public struct ChildMapping<Source: Entity>: AssociationMapping {
    public let field: PartialKeyPath<Source>
    let entity: AnyEntity.Type

    public init<Target: Entity>(field: PartialKeyPath<Source>, entity: Target.Type) {
        self.field = field
        self.entity = entity
    }
}
