public struct ChildMapping<Source: Entity>: AssociationMapping {
    public let field: String
    public let entity: any Entity.Type
    public let mappedBy: String

    public init<Target: Entity>(field: String, entity: Target.Type) {
        self.init(field: field, entity: entity, mappedBy: "")
    }

    public init<Target: Entity>(field: String, entity: Target.Type, mappedBy: String) {
        self.field = field
        self.entity = entity

        if mappedBy.isEmpty {
            self.mappedBy = String(describing: Source.self).components(separatedBy: ".").last!.camelCased
        } else {
            self.mappedBy = mappedBy
        }
    }
}
