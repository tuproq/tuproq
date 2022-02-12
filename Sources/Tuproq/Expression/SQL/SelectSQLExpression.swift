final class SelectSQLExpression: SQLExpression {
    let columns: [ColumnSQLExpression]

    convenience init(columns: String...) {
        self.init(columns: columns)
    }

    convenience init(columns: [String]) {
        let columns = columns.map { column -> ColumnSQLExpression in
            let components = column.components(separatedBy: " ")

            if components.count == 3, components[1].lowercased() == Kind.as.rawValue.lowercased() {
                return ColumnSQLExpression(name: components[0], alias: components[2])
            }

            return ColumnSQLExpression(name: column)
        }

        self.init(columns: columns)
    }

    init(columns: [ColumnSQLExpression]) {
        self.columns = columns
        var raw = "\(Kind.select) "

        if columns.isEmpty {
            raw += Kind.star.rawValue
        } else {
            raw += columns.map({ $0.description }).joined(separator: ", ")
        }

        super.init(raw: raw)
    }
}
