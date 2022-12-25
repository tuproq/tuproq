struct PrimaryKeySQLConstraint: SQLConstraint {
    let name = "PRIMARY KEY"
    let columns: [String]

    init(column: String) {
        self.columns = [column]
    }

    init(columns: [String]) {
        self.columns = columns
    }
}
