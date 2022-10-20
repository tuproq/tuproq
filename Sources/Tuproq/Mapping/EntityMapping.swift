public protocol EntityMapping {
    associatedtype E: Entity

    var entity: E.Type { get }
    var table: String { get }
    var ids: Set<IDMapping<E>> { get }
    var fields: Set<FieldMapping<E>> { get }
    var parents: Set<ParentMapping<E>> { get }
    var children: Set<ChildMapping<E>> { get }
    var siblings: Set<SiblingMapping<E>> { get }
}

public extension EntityMapping {
    var entity: E.Type { E.self }
    var table: String { ORM.namingStrategy.table(entity: entity) }
    var ids: Set<IDMapping<E>> { [.init(column: ORM.namingStrategy.referenceColumn)] }
    var fields: Set<FieldMapping<E>> { .init() }
    var parents: Set<ParentMapping<E>> { .init() }
    var children: Set<ChildMapping<E>> { .init() }
    var siblings: Set<SiblingMapping<E>> { .init() }
}
