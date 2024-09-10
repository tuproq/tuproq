public protocol AssociationMapping: AnyFieldMapping {
    var name: String { get }
    var entity: any Entity.Type { get }
}
