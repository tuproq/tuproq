extension Table {
    struct Column {
        let name: String
        let type: String
        var constraints = [Constraint]()
    }
}
