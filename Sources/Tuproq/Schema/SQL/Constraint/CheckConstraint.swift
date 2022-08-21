struct CheckConstraint: Constraint {
    let name = "CHECK"
    var condition: String
}
