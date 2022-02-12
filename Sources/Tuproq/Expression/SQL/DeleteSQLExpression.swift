final class DeleteSQLExpression: SQLExpression {
    init() {
        super.init(raw: "\(Kind.delete)")
    }
}
