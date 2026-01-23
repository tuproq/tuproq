final class DeleteSQLExpression: SQLExpression, @unchecked Sendable {
    init() {
        super.init(raw: "\(Kind.delete)")
    }
}
