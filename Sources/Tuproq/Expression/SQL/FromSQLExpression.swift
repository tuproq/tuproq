final class FromSQLExpression: SQLExpression {
    let tables: [TableSQLExpression]

    convenience init(tables: String...) {
        self.init(tables: tables)
    }

    convenience init(tables: [String]) {
        let tables = tables.map { table -> TableSQLExpression in
            let components = table.components(separatedBy: " ")

            if components.count == 3, components[1].lowercased() == Kind.as.rawValue.lowercased() {
                return TableSQLExpression(name: components[0], alias: components[2])
            }

            return TableSQLExpression(name: table)
        }

        self.init(tables: tables)
    }

    init(tables: [TableSQLExpression]) {
        self.tables = tables

        super.init(raw: "\(Kind.from) \(tables.map({ $0.description }).joined(separator: ", "))")
    }
}
