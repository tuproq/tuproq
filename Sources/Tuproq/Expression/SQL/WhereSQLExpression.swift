final class WhereSQLExpression: SQLExpression {
    let condition: String

    init(condition: String) {
        self.condition = condition

        super.init(raw: "\(Kind.where) \(condition)")
    }
}
