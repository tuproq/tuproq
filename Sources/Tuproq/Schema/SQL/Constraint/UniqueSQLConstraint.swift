struct UniqueSQLConstraint: SQLConstraint {
    let name = "UNIQUE"
    let table: String
    let columns: Set<String>
    let index: String

    init(
        table: String,
        columns: Set<String>,
        index: String? = nil
    ) {
        self.table = table
        self.columns = columns
        self.index = index ?? "\(table)_\(columns.joined(separator: "_"))_idx"
    }

    init(
        table: String,
        column: String,
        index: String? = nil
    ) {
        self.init(
            table: table,
            columns: [column],
            index: index
        )
    }
}
