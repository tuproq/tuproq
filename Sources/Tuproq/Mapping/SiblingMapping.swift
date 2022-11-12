public struct SiblingMapping<Source: Entity>: AssociationMapping {
    public let field: String
    public let entity: any Entity.Type
    public let mappedBy: String?
    public let inversedBy: String?
    public let joinTable: JoinTable?

    public init<Target: Entity>(field: String, entity: Target.Type, mappedBy: String) {
        self.field = field
        self.entity = entity
        self.mappedBy = mappedBy
        inversedBy = nil
        joinTable = nil
    }

    public init<Target: Entity>(field: String, entity: Target.Type, inversedBy: String, joinTable: JoinTable) {
        self.field = field
        self.entity = entity
        mappedBy = nil
        self.inversedBy = inversedBy
        self.joinTable = joinTable
    }
}
