struct ForeignKeySQLConstraint: SQLConstraint {
    let name = "FOREIGN KEY"
    let columns: [String]
    let relationTable: String
    let relationColumns: [String]
    let cascadeDelete: Bool

    init(
        column: String,
        relationTable: String,
        relationColumn: String,
        cascadeDelete: Bool = false
    ) {
        self.init(
            columns: [column],
            relationTable: relationTable,
            relationColumns: [relationColumn],
            cascadeDelete: cascadeDelete
        )
    }

    init(
        column: String,
        relationTable: String,
        relationColumns: [String],
        cascadeDelete: Bool = false
    ) {
        self.init(
            columns: [column],
            relationTable: relationTable,
            relationColumns: relationColumns,
            cascadeDelete: cascadeDelete
        )
    }

    init(
        columns: [String],
        relationTable: String,
        relationColumn: String,
        cascadeDelete: Bool = false
    ) {
        self.init(
            columns: columns,
            relationTable: relationTable,
            relationColumns: [relationColumn],
            cascadeDelete: cascadeDelete
        )
    }

    init(
        columns: [String],
        relationTable: String,
        relationColumns: [String],
        cascadeDelete: Bool = false
    ) {
        self.columns = columns
        self.relationTable = relationTable
        self.relationColumns = relationColumns
        self.cascadeDelete = cascadeDelete
    }
}
