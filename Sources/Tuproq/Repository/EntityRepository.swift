public protocol EntityRepository {
    associatedtype E: Entity

    var entity: E.Type { get }

    init()
}

public extension EntityRepository {
    var entity: E.Type { E.self }
}
