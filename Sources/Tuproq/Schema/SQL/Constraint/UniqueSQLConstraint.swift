struct UniqueConstraint: Constraint {
    let name = "UNIQUE"
    var column: Table.Column
}
