public struct SiblingMapping: AssociationMapping {
    public let name: String
    public let entity: any Entity.Type
    public let mappedBy: String?
    public let inversedBy: String?
    public let joinTable: JoinTable?

    public init<Target: Entity>(
        _ name: String,
        entity: Target.Type,
        mappedBy: String
    ) {
        self.name = name
        self.entity = entity
        self.mappedBy = mappedBy
        inversedBy = nil
        joinTable = nil
    }

    public init<Target: Entity>(
        _ name: String,
        entity: Target.Type,
        inversedBy: String? = nil,
        joinTable: JoinTable
    ) {
        self.name = name
        self.entity = entity
        mappedBy = nil
        self.inversedBy = inversedBy
        self.joinTable = joinTable
    }
}
