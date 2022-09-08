final class CreateTableSQLExpression: SQLExpression {
    let table: Table

    init(table: Table) {
        self.table = table
        var raw = "\(Kind.createTable) \(table.name)"

        if !table.columns.isEmpty {
            raw += "("
            raw += table.columns.map { column in
                var columnDefinition = "\(column.name) \(column.type)"

                if !column.constraints.isEmpty {
                    columnDefinition += " \(column.constraints.map { $0.name }.joined(separator: " "))"
                }

                return columnDefinition
            }.joined(separator: ", ")
            raw += table.constraints.map { constraint in
                var columnDefinition = ", "

                if let primaryKeyConstraint = constraint as? PrimaryKeyConstraint {
                    columnDefinition += "\(primaryKeyConstraint.name) (\(primaryKeyConstraint.columns.joined(separator: ", ")))"
                } else if let foreignKeyConstraint = constraint as? ForeignKeyConstraint {
                    columnDefinition += "\(foreignKeyConstraint.name) (\(foreignKeyConstraint.column)) REFERENCES \(foreignKeyConstraint.relationTable)(\(foreignKeyConstraint.relationColumn))"
                }

                return columnDefinition
            }.joined(separator: ", ")
            raw += ")"
        }

        super.init(raw: raw)
    }
}
