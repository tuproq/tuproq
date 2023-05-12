final class InsertIntoSQLExpression: SQLExpression {
    let table: String
    let columns: [String]
    let values: [Any?]

    init(table: String, columns: [String] = .init(), values: [Any?]) {
        self.table = table
        self.columns = columns
        self.values = values
        var raw = "\(Kind.insertInto) \(table)"

        if !columns.isEmpty {
            raw += " (\(columns.map({ $0.description }).joined(separator: ", ")))"
        }

        if !values.isEmpty {
            let values = values.map { value in
                if let value = value {
                    if let string = value as? String {
                        return "'\(string)'"
                    }

                    return "\(value)"
                }

                return "\(Kind.null)"
            }.joined(separator: ", ")
            raw += " \(Kind.values) (\(values))"
        }

        super.init(raw: raw)
    }
}
