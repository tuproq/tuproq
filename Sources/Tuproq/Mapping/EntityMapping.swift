public protocol EntityMapping {
    associatedtype E: Entity

    var namingStrategy: NamingStrategy { get }
    var entity: E.Type { get }
    var table: String { get }
    var ids: Set<IDMapping> { get }
    var fields: Set<FieldMapping> { get }
    var parents: Set<ParentMapping> { get }
    var children: Set<ChildMapping> { get }
    var siblings: Set<SiblingMapping> { get }
}

public extension EntityMapping {
    var namingStrategy: NamingStrategy { SnakeCaseNamingStrategy() }
    var table: String { namingStrategy.tableName(entity: entity) }
    var ids: Set<IDMapping> { [.init(name: namingStrategy.referenceColumnName)] }
    var fields: Set<FieldMapping> { .init() }
    var parents: Set<ParentMapping> { .init() }
    var children: Set<ChildMapping> { .init() }
    var siblings: Set<SiblingMapping> { .init() }
}
