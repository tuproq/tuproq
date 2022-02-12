final class HavingSQLExpression: SQLExpression {
    let condition: String

    init(condition: String) {
        self.condition = condition

        super.init(raw: "\(Kind.having) \(condition)")
    }
}
