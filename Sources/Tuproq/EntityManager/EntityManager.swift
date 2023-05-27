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
    func refresh<E: Entity>(_ entity: inout E) throws
    func remove<E: Entity>(_ entity: E)
}

public extension EntityManager {
    func getRepository<R: EntityRepository>(_ entityType: R.E.Type) -> R {
        R(entityManager: self)
    }
}
