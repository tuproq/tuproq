struct DefaultSQLConstraint: SQLConstraint {
    let name = "DEFAULT"
    var value: String
}
