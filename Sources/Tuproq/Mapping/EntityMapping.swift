public protocol EntityMapping: Sendable {
    associatedtype E: Entity

    typealias Constraint = ConstraintType
    typealias ID = IDMapping
    typealias Field = FieldMapping
    typealias Parent = ParentMapping
    typealias Child = ChildMapping
    typealias Sibling = SiblingMapping

    var entity: E.Type { get }
    var table: String { get }
    var constraints: Set<Constraint> { get }
    var id: ID { get }
    var fields: Set<Field> { get }
    var parents: Set<Parent> { get }
    var children: Set<Child> { get }
    var siblings: Set<Sibling> { get }
}

public extension EntityMapping {
    var entity: E.Type { E.self }
    var table: String { Configuration.namingStrategy.table(entity: entity) }
    var constraints: Set<Constraint> { .init() }
    var id: ID { .init() }
    var fields: Set<Field> { .init() }
    var parents: Set<Parent> { .init() }
    var children: Set<Child> { .init() }
    var siblings: Set<Sibling> { .init() }
}
