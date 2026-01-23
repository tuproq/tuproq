public protocol QueryBuilder: Sendable {
    associatedtype E: Expression
    associatedtype Q: Query

    mutating func addExpression(_ expression: E)
    func getExpressions() -> [E]

    func getQuery() -> Q
}
