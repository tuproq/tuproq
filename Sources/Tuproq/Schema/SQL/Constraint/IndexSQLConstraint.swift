struct IndexSQLConstraint: SQLConstraint {
    let name = "INDEX"
    var key: String
    var columns = [Table.Column]()
}
