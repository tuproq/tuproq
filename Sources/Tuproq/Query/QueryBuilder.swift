public protocol QueryBuilder {
    associatedtype Q: Query

    func getQuery() -> Q
    func execute() async throws
}
