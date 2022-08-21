public protocol EntityMapping {
    associatedtype E: Entity

    var strategy: MappingStrategy { get }
    var entity: E.Type { get }
    var table: String { get }
    var fields: Set<FieldMapping> { get }
}

extension EntityMapping {
    var strategy: MappingStrategy { .same }

    var table: String {
        switch strategy {
        case .same: return String(describing: entity).lowercased()
        case .snakeCased: return String(describing: entity).snakeCased
        }
    }
}
