public protocol QueryBuilder: Sendable {
    associatedtype E: Expression
    associatedtype Q: Query

    mutating func addExpression(_ expression: E)
    func getExpressions() -> [E]

    func getQuery(bindings: [(String, Any?)]) -> Q
}

public extension QueryBuilder {
    func getQuery(bindings: [(String, Any?)] = .init()) -> Q {
        getQuery(bindings: bindings)
    }
}
