public struct SQLQuery: Query {
    public let raw: String
    public let bindings: [(String, Any?)]

    public init(
        _ raw: String,
        bindings: [(String, Any?)] = .init()
    ) {
        self.raw = raw
        self.bindings = bindings
    }
}
