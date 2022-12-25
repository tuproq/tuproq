struct CheckSQLConstraint: SQLConstraint {
    let name = "CHECK"
    var condition: String
}
