public protocol EntityManager: AnyObject {
    associatedtype Q: QueryBuilder

    init(connection: Connection)

    func createQueryBuilder() -> Q
    func find<E: Entity, I: Hashable>(_ entityType: E.Type, id: I) async throws -> E?
    func flush() async throws
    func getRepository<R: Repository>(_ repositoryType: R.Type) -> R
    func persist<E: Entity>(_ entity: inout E) throws
    func refresh<E: Entity>(_ entity: inout E) throws
    func remove<E: Entity>(_ entity: E)
}
