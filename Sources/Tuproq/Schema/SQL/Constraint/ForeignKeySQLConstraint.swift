struct ForeignKeySQLConstraint: SQLConstraint {
    let name = "FOREIGN KEY"
    let columns: [String]
    let relationTable: String
    let relationColumns: [String]
    let cascadeDelete: Bool

    init(column: String, relationTable: String, relationColumn: String, cascadeDelete: Bool = false) {
        self.columns = [column]
        self.relationTable = relationTable
        self.relationColumns = [relationColumn]
        self.cascadeDelete = cascadeDelete
    }

    init(column: String, relationTable: String, relationColumns: [String], cascadeDelete: Bool = false) {
        self.columns = [column]
        self.relationTable = relationTable
        self.relationColumns = relationColumns
        self.cascadeDelete = cascadeDelete
    }

    init(columns: [String], relationTable: String, relationColumn: String, cascadeDelete: Bool = false) {
        self.columns = columns
        self.relationTable = relationTable
        self.relationColumns = [relationColumn]
        self.cascadeDelete = cascadeDelete
    }

    init(columns: [String], relationTable: String, relationColumns: [String], cascadeDelete: Bool = false) {
        self.columns = columns
        self.relationTable = relationTable
        self.relationColumns = relationColumns
        self.cascadeDelete = cascadeDelete
    }
}
