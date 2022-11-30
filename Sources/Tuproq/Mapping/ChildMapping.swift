public struct ChildMapping: AssociationMapping {
    public let field: String
    public let entity: any Entity.Type
    public let mappedBy: String
    public let isUnique: Bool

    public init<Target: Entity>(field: String, entity: Target.Type, mappedBy: String, isUnique: Bool = false) {
        self.field = field
        self.entity = entity
        self.mappedBy = mappedBy
        self.isUnique = isUnique
    }
}
