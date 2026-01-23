final class AndSQLExpression: SQLExpression, @unchecked Sendable {
    let condition: String

    init(condition: String) {
        self.condition = condition

        super.init(raw: "\(Kind.and) \(condition)")
    }
}
