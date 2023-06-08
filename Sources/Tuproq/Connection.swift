public protocol Connection {
    var driver: DatabaseDriver { get }

    func open() async throws
    func close() async throws

    func beginTransaction() async throws
    func commitTransaction() async throws
    func rollbackTransaction() async throws

    @discardableResult
    func query(_ string: String, arguments parameters: [Codable?]) async throws -> [[String: Any?]]

    @discardableResult
    func query(_ string: String, arguments parameters: Codable?...) async throws -> [[String: Any?]]
}

public extension Connection {
    @discardableResult
    func query(_ string: String, arguments parameters: Codable?...) async throws -> [[String: Any?]] {
        try await query(string, arguments: parameters)
    }
}
