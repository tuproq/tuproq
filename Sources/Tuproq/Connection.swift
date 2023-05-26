public protocol Connection {
    var driver: DatabaseDriver { get }

    func open() async throws
    func close() async throws
    @discardableResult
    func query(_ string: String) async throws -> [[String: Codable?]]
}
