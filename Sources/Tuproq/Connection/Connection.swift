import NIOCore

public protocol Connection: AnyObject, Sendable {
    var id: ObjectIdentifier { get }
    var isOpen: Bool { get }
    var channel: Channel { get }

    func close() async throws

    func beginTransaction() async throws
    func commitTransaction() async throws
    func rollbackTransaction() async throws

    @discardableResult
    func query(
        _ string: String,
        arguments: [Codable?]
    ) async throws -> QueryResult?

    @discardableResult
    func query(
        _ string: String,
        arguments: Codable?...
    ) async throws -> QueryResult?
}

public extension Connection {
    var id: ObjectIdentifier { .init(self) }

    @discardableResult
    func query(
        _ string: String,
        arguments: Codable?...
    ) async throws -> QueryResult? {
        try await query(
            string,
            arguments: arguments
        )
    }
}
