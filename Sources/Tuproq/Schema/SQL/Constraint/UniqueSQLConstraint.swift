struct UniqueSQLConstraint: SQLConstraint {
    let name = "UNIQUE"
    var column: String
}
