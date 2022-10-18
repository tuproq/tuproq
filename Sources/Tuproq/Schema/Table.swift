public struct Table {
    public var name: String
    public var columns = [Column]()
    public var constraints = [Constraint]()
}

public extension Table {
    struct Column {
        let name: String
        let type: String
        var constraints = [Constraint]()
    }
}
