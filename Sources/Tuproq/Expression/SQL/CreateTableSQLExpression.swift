final class CreateTableSQLExpression: SQLExpression {
    let table: Table

    init(table: Table) {
        self.table = table
        var raw = "\(Kind.createTable) \(table.name)"

        if !table.columns.isEmpty {
            raw += "("
            raw += table.columns.map { column in
                var columnDefinition = "\(column.name) \(column.type)"

                if let length = column.length {
                    columnDefinition += "(\(length))"
                }

                if !column.constraints.isEmpty {
                    columnDefinition += " \(column.constraints.map { $0.name }.joined(separator: " "))"
                }

                return columnDefinition
            }.joined(separator: ", ")
            raw += ")"
        }

        super.init(raw: raw)
    }
}
