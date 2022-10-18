public struct ChildMapping: AssociationMapping {
    public let field: String
    let entity: Any
    public let isUnique: Bool

    public init<E: Entity>(field: String, entity: E.Type, isUnique: Bool = false) {
        self.field = field
        self.entity = entity
        self.isUnique = isUnique
    }
}
