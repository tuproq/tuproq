public struct SQLQuery: Query {
    public let raw: String
    public let bindings: [(String, Codable?)]

    public init(
        _ raw: String,
        bindings: [(String, Codable?)] = .init()
    ) {
        self.raw = raw
        self.bindings = bindings
    }
}
