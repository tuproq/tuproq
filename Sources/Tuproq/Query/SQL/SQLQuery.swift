public struct SQLQuery: Query {
    public let raw: String

    public init(_ raw: String) {
        self.raw = raw
    }
}
