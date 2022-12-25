struct UniqueSQLConstraint: SQLConstraint, ExpressibleByArrayLiteral, ExpressibleByStringLiteral {
    let name = "UNIQUE"
    let columns: Set<String>
    let index: String

    init(stringLiteral column: String) {
        self.init(columns: [column])
    }

    init(arrayLiteral columns: String...) {
        self.init(columns: .init(columns))
    }

    init(column: String, index: String? = nil) {
        self.init(columns: [column], index: index)
    }

    init(columns: Set<String>, index: String? = nil) {
        self.columns = columns
        self.index = index ?? "\(columns.joined(separator: "_"))_idx"
    }
}
