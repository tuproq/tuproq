final class OrderBySQLExpression: SQLExpression {
    let columns: [(String, Bool)]

    init(columns: [(String, Bool)]) {
        self.columns = columns
        var raw = "\(Kind.orderBy)"

        for (index, column) in columns.enumerated() {
            let sorting: Sorting = column.1 ? .asc : .desc
            raw += " \(column.0) \(sorting)"

            if index != columns.endIndex - 1 {
                raw += ","
            }
        }

        super.init(raw: raw)
    }
}

extension OrderBySQLExpression {
    enum Sorting: String, CustomStringConvertible {
        case asc = "ASC"
        case desc = "DESC"

        var description: String { rawValue }
    }
}
