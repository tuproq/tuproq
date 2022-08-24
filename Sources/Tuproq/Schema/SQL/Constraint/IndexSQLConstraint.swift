struct IndexConstraint: Constraint {
    let name = "INDEX"
    var key: String
    var columns = [Table.Column]()
}
