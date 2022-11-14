public protocol Connection {
    var driver: DatabaseDriver { get }

    @discardableResult
    func connect() async throws -> Self
    func close() async throws
    func query(_ string: String) async throws -> [Result]
}
