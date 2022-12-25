struct UniqueSQLConstraint: Constraint {
    let name = "UNIQUE"
    var column: String
}
