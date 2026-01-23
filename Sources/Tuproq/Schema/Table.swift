public struct Table: Sendable {
    public var name: String
    public var columns = [Column]()
    public var constraints = [SQLConstraint]()
}

extension Table {
    public struct Column: Sendable {
        public let name: String
        public let type: String
        public var constraints = [SQLConstraint]()
    }
}
