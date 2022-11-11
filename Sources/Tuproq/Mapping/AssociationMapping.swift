public protocol AssociationMapping: AnyFieldMapping {
    var field: String { get }
    var entity: any Entity.Type { get }
}
