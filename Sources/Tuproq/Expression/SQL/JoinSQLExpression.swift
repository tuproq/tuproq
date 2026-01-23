final class JoinSQLExpression: SQLExpression, @unchecked Sendable {
    let table: TableSQLExpression
    let condition: String

    init(
        table: TableSQLExpression,
        condition: String
    ) {
        self.table = table
        self.condition = condition

        super.init(raw: "\(Kind.join) \(table) \(Kind.on) \(condition)")
    }
}
