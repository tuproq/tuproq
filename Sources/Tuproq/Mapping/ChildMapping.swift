public struct ChildMapping<Source: Entity>: AssociationMapping {
    public let field: String
    public let entity: any Entity.Type
    public let mappedBy: String
    public let isUnique: Bool

    public init<Target: Entity>(field: String, entity: Target.Type, isUnique: Bool = false) {
        self.init(field: field, entity: entity, mappedBy: "", isUnique: isUnique)
    }

    public init<Target: Entity>(field: String, entity: Target.Type, mappedBy: String, isUnique: Bool = false) {
        self.field = field
        self.entity = entity

        if mappedBy.isEmpty {
            self.mappedBy = String(describing: Source.self).components(separatedBy: ".").last!.camelCased
        } else {
            self.mappedBy = mappedBy
        }

        self.isUnique = isUnique
    }
}
