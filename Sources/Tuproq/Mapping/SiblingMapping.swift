public struct SiblingMapping: AssociationMapping {
    public let field: String
    public let entity: any Entity.Type
    public let mappedBy: String?
    public let inversedBy: String?
    public let joinTable: JoinTable?

    public init<Target: Entity>(
        field: String,
        entity: Target.Type,
        mappedBy: String? = nil,
        inversedBy: String? = nil,
        joinTable: JoinTable? = nil
    ) {
        self.field = field
        self.entity = entity
        self.mappedBy = mappedBy
        self.inversedBy = inversedBy
        self.joinTable = joinTable
    }
}
