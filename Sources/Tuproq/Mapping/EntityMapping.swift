public protocol EntityMapping {
    associatedtype E: Entity

    var strategy: MappingStrategy { get }
    var entity: E.Type { get }
    var table: String { get }
    var id: IDMapping { get }
    var fields: Set<FieldMapping> { get }
    var parents: Set<ParentMapping> { get }
}

public extension EntityMapping {
    var strategy: MappingStrategy { .same }
    var id: IDMapping { .init(name: "id") }
    var parents: Set<ParentMapping> { .init() }

    var table: String {
        switch strategy {
        case .same: return String(describing: entity)
        case .snakeCased: return String(describing: entity).snakeCased
        }
    }
}
