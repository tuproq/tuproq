public protocol EntityRepository {
    associatedtype E: Entity

    var entity: E.Type { get }

    init(entityManager: any EntityManager)
}

public extension EntityRepository {
    var entity: E.Type { E.self }
}
