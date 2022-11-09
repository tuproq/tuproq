public struct ChildMapping: AssociationMapping {
    public let field: String
    public let entity: any Entity.Type
    public let mappedBy: String?

    public init<Target: Entity>(field: String, entity: Target.Type, mappedBy: String? = nil) {
        self.field = field
        self.entity = entity
        self.mappedBy = mappedBy
    }
}
