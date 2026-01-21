public protocol QueryBuilder: AnyObject {
    associatedtype E: Expression
    associatedtype Q: Query

    func addExpression(_ expression: E)
    func getExpressions() -> [E]

    func getQuery() -> Q
}
