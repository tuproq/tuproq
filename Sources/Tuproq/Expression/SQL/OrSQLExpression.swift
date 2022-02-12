final class OrSQLExpression: SQLExpression {
    let condition: String

    init(condition: String) {
        self.condition = condition

        super.init(raw: "\(Kind.or) \(condition)")
    }
}
