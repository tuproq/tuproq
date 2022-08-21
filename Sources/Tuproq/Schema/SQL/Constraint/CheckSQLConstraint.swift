struct CheckSQLConstraint: Constraint {
    let name = "CHECK"
    var condition: String
}
