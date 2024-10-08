import NIOCore

public protocol Connection: AnyObject {
    var id: ObjectIdentifier { get }
    var isOpen: Bool { get }
    var channel: Channel { get }

    func close() async throws

    func beginTransaction() async throws
    func commitTransaction() async throws
    func rollbackTransaction() async throws

    @discardableResult
    func query(_ string: String, arguments: [Codable?]) async throws -> QueryResult?

    @discardableResult
    func query(_ string: String, arguments: Codable?...) async throws -> QueryResult?
}

public extension Connection {
    var id: ObjectIdentifier { .init(self) }

    @discardableResult
    func query(_ string: String, arguments: Codable?...) async throws -> QueryResult? {
        try await query(string, arguments: arguments)
    }
}

public struct Column: CustomStringConvertible, Hashable {
    public let name: String
    public let tableID: Int32 // TODO: a temporary solution (PostgreSQL specific)
    public var description: String { name }

    public init(name: String, tableID: Int32) {
        self.name = name
        self.tableID = tableID
    }
}

public final class QueryResult {
    public let columns: [Column]
    public internal(set) var rows = [[Codable?]]()

    public init(columns: [Column], rows: [[Codable?]]) {
        self.columns = columns
        self.rows = rows
    }
}
