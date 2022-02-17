public protocol Repository {
    associatedtype EntityType: Entity

    var entityType: EntityType.Type { get }

    init()

    func find<I: Encodable>(id: I) async throws -> EntityType?
}

extension Repository {
    public var entityType: EntityType.Type { EntityType.self }

    public func find<I: Encodable>(id: I) async throws -> EntityType? {
        // TODO: implement
        return nil
    }
}
