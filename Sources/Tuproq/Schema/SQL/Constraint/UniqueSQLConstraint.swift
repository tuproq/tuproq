struct UniqueSQLConstraint: SQLConstraint, ExpressibleByArrayLiteral, ExpressibleByStringLiteral {
    let name = "UNIQUE"
    let columns: Set<String>
    let index: String?

    init(column: String, index: String? = nil) {
        columns = [column]
        self.index = index
    }

    init(stringLiteral column: String) {
        columns = [column]
        index = nil
    }

    init(columns: Set<String>, index: String? = nil) {
        self.columns = columns
        self.index = index
    }

    init(arrayLiteral columns: String...) {
        self.columns = .init(columns)
        index = nil
    }
}
