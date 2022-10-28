public protocol Repository {
    associatedtype E: Entity

    var entity: E.Type { get }

    init()
}

public extension Repository {
    var entity: E.Type { E.self }
}
