public protocol ObjectManager {
    func detach<E: Entity>(_ entity: E)
    func find<E: Entity, I: Hashable>(_ entityType: E.Type, id: I) async throws -> E?
    func flush<E: Entity>(_ entity: E?) async throws
    func getRepository<R: Repository>(_ repositoryType: R.Type) -> R
    func merge<E: Entity>(_ entity: E)
    func persist<E: Entity>(_ entity: E) throws
    func refresh<E: Entity>(_ entity: E)
    func remove<E: Entity>(_ entity: E)
}
