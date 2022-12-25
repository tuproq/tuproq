struct IndexSQLConstraint: Constraint {
    let name = "INDEX"
    var key: String
    var columns = [Table.Column]()
}
