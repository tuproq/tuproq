final class HavingSQLExpression: SQLExpression, @unchecked Sendable {
    let condition: String

    init(condition: String) {
        self.condition = condition

        super.init(raw: "\(Kind.having) \(condition)")
    }
}
