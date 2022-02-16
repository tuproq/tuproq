final class OrderBySQLExpression: SQLExpression {
    let columns: [(String, Sorting)]

    init(columns: [(String, Sorting)]) {
        self.columns = columns
        var raw = "\(Kind.orderBy)"

        for (index, column) in columns.enumerated() {
            raw += " \(column.0) \(column.1)"

            if index != columns.endIndex - 1 {
                raw += ","
            }
        }

        super.init(raw: raw)
    }
}
