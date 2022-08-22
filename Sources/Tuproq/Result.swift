public final class Result {
    public let columns: [String]
    public let rows: [[Any?]]

    init(columns: [String], rows: [[Any?]]) {
        self.columns = columns
        self.rows = rows
    }
}
