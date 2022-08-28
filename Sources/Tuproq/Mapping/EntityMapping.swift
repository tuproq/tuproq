public protocol EntityMapping {
    associatedtype E: Entity

    var strategy: MappingStrategy { get }
    var entity: E.Type { get }
    var table: String { get }
    var id: IDMapping { get }
    var fields: Set<FieldMapping> { get }
}

extension EntityMapping {
    var strategy: MappingStrategy { .same }
    var id: IDMapping { .init(name: "id") }

    var table: String {
        switch strategy {
        case .same: return String(describing: entity)
        case .snakeCased: return String(describing: entity).snakeCased
        }
    }
}
