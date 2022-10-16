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

            if !table.constraints.isEmpty {
                raw += ", "
            }

            raw += table.constraints.map { constraint in
                var constraintDefinition = ""

                if let primaryKey = constraint as? PrimaryKeyConstraint {
                    constraintDefinition += "\(primaryKey.name) (\(primaryKey.columns.joined(separator: ", ")))"
                } else if let foreignKey = constraint as? ForeignKeyConstraint {
                    constraintDefinition += """
                    \(foreignKey.name) (\(foreignKey.columns.joined(separator: ", "))) \
                    REFERENCES \(foreignKey.relationTable)(\(foreignKey.relationColumns.joined(separator: ", ")))
                    """
                }

                return constraintDefinition
            }.joined(separator: ", ")
            raw += ")"
        }

        super.init(raw: raw)
    }
}
