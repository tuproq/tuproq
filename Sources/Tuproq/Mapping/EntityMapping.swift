public protocol EntityMapping {
    associatedtype E: Entity

    static var namingStrategy: NamingStrategy { get }
    var entity: E.Type { get }
    var table: String { get }
    var ids: Set<IDMapping> { get }
    var fields: Set<FieldMapping> { get }
    var parents: Set<ParentMapping> { get }
    var children: Set<ChildMapping> { get }
    var siblings: Set<SiblingMapping> { get }
}

public extension EntityMapping {
    static var namingStrategy: NamingStrategy { SnakeCaseNamingStrategy() }
    var table: String { Self.namingStrategy.table(entity: entity) }
    var ids: Set<IDMapping> { [.init(name: Self.namingStrategy.referenceColumn)] }
    var fields: Set<FieldMapping> { .init() }
    var parents: Set<ParentMapping> { .init() }
    var children: Set<ChildMapping> { .init() }
    var siblings: Set<SiblingMapping> { .init() }
}
