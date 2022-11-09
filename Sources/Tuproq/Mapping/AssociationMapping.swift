public protocol AssociationMapping: AnyMapping {
    var field: String { get }
    var entity: any Entity.Type { get }
}
