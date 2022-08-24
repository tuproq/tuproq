extension Table {
    struct Column {
        let name: String
        let type: String
        var length: UInt? = nil
        var constraints = [Constraint]()
    }
}
