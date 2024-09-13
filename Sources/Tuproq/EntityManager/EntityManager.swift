public protocol EntityManager: AnyObject {
    associatedtype Q: QueryBuilder

    var configuration: Configuration { set get }

    func createQueryBuilder() -> Q
    func find<E: Entity>(_ entityType: E.Type, id: E.ID) async throws -> E?
    func flush() async throws
    func getRepository<R: EntityRepository>(_ entityType: R.E.Type) -> R
    func persist<E: Entity>(_ entity: inout E) throws
    func remove<E: Entity>(_ entity: E) throws

    @discardableResult
    func query<E: Entity>(
        _ string: String,
        arguments: [Codable?]
    ) async throws -> [E]

    @discardableResult
    func query<E: Entity>(
        _ string: String,
        arguments: Codable?...
    ) async throws -> [E]

    @discardableResult
    func query(
        _ string: String,
        arguments: [Codable?]
    ) async throws -> [[String: Any?]]

    @discardableResult
    func query(
        _ string: String,
        arguments: Codable?...
    ) async throws -> [[String: Any?]]

    func propertyValueChanged<E: Entity>(
        _ entity: E,
        name: String,
        oldValue: Codable?,
        newValue: Codable?
    )
}

public extension EntityManager {
    func getRepository<R: EntityRepository>(_ entityType: R.E.Type) -> R {
        .init(entityManager: self)
    }

    func remove<E: SoftDeletableEntity>(
        _ entity: inout E,
        isSoft: Bool = true
    ) throws {
        isSoft ? entity.deletedDate = .init() : try remove(entity)
    }

    @discardableResult
    func query<E: Entity>(
        _ string: String,
        arguments: Codable?...
    ) async throws -> [E] {
        try await query(
            string,
            arguments: arguments
        )
    }

    @discardableResult
    func query(
        _ string: String,
        arguments: Codable?...
    ) async throws -> [[String: Any?]] {
        try await query(
            string,
            arguments: arguments
        )
    }
}
