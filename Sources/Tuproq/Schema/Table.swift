public struct Table {
    public var name: String
    public var columns = [Column]()
    public var constraints = [SQLConstraint]()
}

extension Table {
    public struct Column {
        public let name: String
        public let type: String
        public var constraints = [SQLConstraint]()
    }
}
