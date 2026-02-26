public protocol Query: Expression {
    var bindings: [Codable] { get }
}
