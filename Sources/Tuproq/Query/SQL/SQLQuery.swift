public struct SQLQuery: Query {
    public let raw: String
    public let bindings: [Codable]

    public init(
        _ raw: String,
        bindings: [Codable] = .init()
    ) {
        self.raw = raw
        self.bindings = bindings
    }
}
