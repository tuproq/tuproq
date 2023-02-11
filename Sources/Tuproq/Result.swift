public final class Result {
    public let columns: [String]
    public let rows: [[Any?]]

    public init(columns: [String], rows: [[Any?]]) {
        self.columns = columns
        self.rows = rows
    }
}
