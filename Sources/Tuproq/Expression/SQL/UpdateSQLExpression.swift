final class UpdateSQLExpression: SQLExpression {
    let table: String
    let values: [String: Any?]

    init(table: String, values: [String: Any?]) {
        self.table = table
        self.values = values

        super.init(raw: """
        \(Kind.update) \(table) \
        \(Kind.set) \(values.map({ "\($0.key) = \($0.value ?? "NULL")" }).joined(separator: ", "))
        """
        )
    }
}
