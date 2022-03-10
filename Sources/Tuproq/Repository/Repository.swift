public protocol Repository {
    associatedtype E: Entity

    var entityType: E.Type { get }

    init()
}

extension Repository {
    public var entityType: E.Type { E.self }
}
