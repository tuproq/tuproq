public protocol Query: Expression {
    var bindings: [(String, Any?)] { get }
}
