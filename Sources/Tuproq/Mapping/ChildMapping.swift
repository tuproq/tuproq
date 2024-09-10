public struct ChildMapping: AssociationMapping {
    public let name: String
    public let entity: any Entity.Type
    public let mappedBy: String
    public let isUnique: Bool

    public init<Target: Entity>(
        _ name: String,
        entity: Target.Type,
        mappedBy: String,
        isUnique: Bool = false
    ) {
        self.name = name
        self.entity = entity
        self.mappedBy = mappedBy
        self.isUnique = isUnique
    }
}
