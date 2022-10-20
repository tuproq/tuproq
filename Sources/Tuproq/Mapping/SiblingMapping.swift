public struct SiblingMapping<Source: Entity>: AssociationMapping {
    public let field: PartialKeyPath<Source>
    let entity: AnyEntity.Type
    public let joinTable: JoinTable?

    public init<Target: Entity>(field: PartialKeyPath<Source>, entity: Target.Type, joinTable: JoinTable? = nil) {
        self.field = field
        self.entity = entity
        self.joinTable = joinTable
    }
}
