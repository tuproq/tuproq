public protocol EntityMapping {
    associatedtype E: Entity

    var strategy: MappingStrategy { get }
    var entity: E.Type { get }
    var table: String { get }
    var ids: Set<IDMapping> { get }
    var fields: Set<FieldMapping> { get }
    var parents: Set<ParentMapping> { get }
    var children: Set<ChildMapping> { get }
}

public extension EntityMapping {
    var strategy: MappingStrategy { .same }
    var ids: Set<IDMapping> { [.init(name: "id")] }
    var fields: Set<FieldMapping> { .init() }
    var parents: Set<ParentMapping> { .init() }
    var children: Set<ChildMapping> { .init() }

    var table: String {
        switch strategy {
        case .same: return String(describing: entity)
        case .snakeCased: return String(describing: entity).snakeCased
        }
    }
}
