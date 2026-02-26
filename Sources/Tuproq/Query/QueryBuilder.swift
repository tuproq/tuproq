public protocol QueryBuilder: Sendable {
    associatedtype E: Expression
    associatedtype Q: Query

    mutating func addExpression(_ expression: E)
    func getExpressions() -> [E]

    func getQuery(bindings: [(String, Codable?)]) -> Q
}

public extension QueryBuilder {
    func getQuery(bindings: [(String, Codable?)] = .init()) -> Q {
        getQuery(bindings: bindings)
    }
}
