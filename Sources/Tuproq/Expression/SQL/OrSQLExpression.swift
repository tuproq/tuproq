final class OrSQLExpression: SQLExpression, @unchecked Sendable {
    let condition: String

    init(condition: String) {
        self.condition = condition

        super.init(raw: "\(Kind.or) \(condition)")
    }
}
