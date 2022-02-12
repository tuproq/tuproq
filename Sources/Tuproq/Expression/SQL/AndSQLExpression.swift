final class AndSQLExpression: SQLExpression {
    let condition: String

    init(condition: String) {
        self.condition = condition

        super.init(raw: "\(Kind.and) \(condition)")
    }
}
