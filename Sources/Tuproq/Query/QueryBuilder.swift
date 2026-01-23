public protocol QueryBuilder {
    associatedtype E: Expression
    associatedtype Q: Query

    func addExpression(_ expression: E)
    func getExpressions() -> [E]

    func getQuery() -> Q
}
