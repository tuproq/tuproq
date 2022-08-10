final class CreateTableSQLExpression: SQLExpression {
    let table: Table

    init(table: Table) {
        self.table = table
        var raw = "\(Kind.createTable) \(table.name)"

        if !table.columns.isEmpty {
            raw += "{"
            raw += table.columns.map { "\($0.name) \($0.type)" }.joined(separator: ", ")
            raw += "}"
        }

        super.init(raw: raw)
    }
}
