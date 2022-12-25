struct ForeignKeySQLConstraint: Constraint {
    let name = "FOREIGN KEY"
    let columns: [String]
    let relationTable: String
    let relationColumns: [String]

    init(column: String, relationTable: String, relationColumn: String) {
        self.columns = [column]
        self.relationTable = relationTable
        self.relationColumns = [relationColumn]
    }

    init(column: String, relationTable: String, relationColumns: [String]) {
        self.columns = [column]
        self.relationTable = relationTable
        self.relationColumns = relationColumns
    }

    init(columns: [String], relationTable: String, relationColumn: String) {
        self.columns = columns
        self.relationTable = relationTable
        self.relationColumns = [relationColumn]
    }

    init(columns: [String], relationTable: String, relationColumns: [String]) {
        self.columns = columns
        self.relationTable = relationTable
        self.relationColumns = relationColumns
    }
}
