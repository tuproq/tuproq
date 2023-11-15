public protocol EntityManager: AnyObject {
    associatedtype Q: QueryBuilder

    var connection: Connection { get }
    var configuration: Configuration { set get }

    init(connection: Connection, configuration: Configuration)

    func createQueryBuilder() -> Q
    func find<E: Entity>(_ entityType: E.Type, id: E.ID) async throws -> E?
    func flush() async throws
    func getRepository<R: EntityRepository>(_ entityType: R.E.Type) -> R
    func persist<E: Entity>(_ entity: inout E) throws
    func remove<E: Entity>(_ entity: E) throws

    @discardableResult
    func query<E: Entity>(_ string: String, arguments parameters: [Codable?]) async throws -> [E] // TODO: a temporary solution

    @discardableResult
    func query<E: Entity>(_ string: String, arguments parameters: Codable?...) async throws -> [E] // TODO: a temporary solution

    @discardableResult
    func query(_ string: String, arguments parameters: [Codable?]) async throws -> [[String: Any?]] // TODO: a temporary solution

    @discardableResult
    func query(_ string: String, arguments parameters: Codable?...) async throws -> [[String: Any?]] // TODO: a temporary solution

    func propertyChanged<E: Entity>(entity: E, propertyName: String, oldValue: Codable?, newValue: Codable?) // TODO: a temporary solution
}

public extension EntityManager {
    func getRepository<R: EntityRepository>(_ entityType: R.E.Type) -> R {
        R(entityManager: self)
    }

    // TODO: a temporary solution
    @discardableResult
    func query<E: Entity>(_ string: String, arguments parameters: Codable?...) async throws -> [E] {
        try await query(string, arguments: parameters)
    }

    // TODO: a temporary solution
    @discardableResult
    func query(_ string: String, arguments parameters: Codable?...) async throws -> [[String: Any?]] {
        try await query(string, arguments: parameters)
    }
}
