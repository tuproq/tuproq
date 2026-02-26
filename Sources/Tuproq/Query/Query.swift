public protocol Query: Expression {
    var bindings: [(String, Codable?)] { get }
}
