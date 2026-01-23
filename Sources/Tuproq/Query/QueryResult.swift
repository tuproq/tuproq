public final class QueryResult {
    public let columns: [Column]
    public internal(set) var rows = [[Codable?]]()

    public init(columns: [Column], rows: [[Codable?]]) {
        self.columns = columns
        self.rows = rows
    }
}

extension QueryResult {
    public struct Column: CustomStringConvertible, Hashable, Sendable {
        public let name: String
        public let tableID: Int32 // TODO: a temporary solution (PostgreSQL specific)
        public var description: String { name }
        
        public init(name: String, tableID: Int32) {
            self.name = name
            self.tableID = tableID
        }
    }
}
