struct ForeignKeyConstraint: Constraint {
    let name = "FOREIGN KEY"
    let column: String
    let relationTable: String
    let relationColumn: String
}
