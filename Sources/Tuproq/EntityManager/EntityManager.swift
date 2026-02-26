public protocol EntityManager: AnyObject, Sendable {
    associatedtype Q: QueryBuilder

    var configuration: Configuration { get }

    func createQueryBuilder() -> Q
    func find<E: Entity>(_ entityType: E.Type, id: E.ID) async throws -> E?
    func flush() async throws
    func getRepository<R: EntityRepository>(_ entityType: R.E.Type) -> R
    func persist<E: Entity>(_ entity: inout E) async throws
    func remove<E: Entity>(_ entity: E) async throws

    @discardableResult
    func query<E: Entity>(
        _ string: String,
        arguments: [Any?]
    ) async throws -> [E]

    @discardableResult
    func query(
        _ string: String,
        arguments: [Any?]
    ) async throws -> [[String: Any?]]
}

public extension EntityManager {
    func getRepository<R: EntityRepository>(_ entityType: R.E.Type) -> R {
        .init(entityManager: self)
    }

    func remove<E: SoftDeletableEntity>(
        _ entity: inout E,
        isSoft: Bool = true
    ) async throws {
        isSoft ? entity.deletedDate = .init() : try await remove(entity)
    }

    @discardableResult
    func query<E: Entity>(
        _ string: String,
        arguments: Any?...
    ) async throws -> [E] {
        try await query(
            string,
            arguments: arguments
        )
    }

    @discardableResult
    func query(
        _ string: String,
        arguments: Any?...
    ) async throws -> [[String: Any?]] {
        try await query(
            string,
            arguments: arguments
        )
    }
}
