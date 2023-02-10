public struct JoinTable: Hashable {
    public let name: String
    public let columns: Set<Column>
    public let inverseColumns: Set<Column>

    public init(name: String, column: Column, inverseColumn: Column) {
        self.init(name: name, columns: [column], inverseColumns: [inverseColumn])
    }

    public init(name: String, columns: Set<Column>, inverseColumns: Set<Column>) {
        self.name = name
        self.columns = columns
        self.inverseColumns = inverseColumns
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

extension JoinTable {
    public struct Column: ExpressibleByStringLiteral, Hashable {
        public let name: String
        public let referenceColumn: String
        public let isUnique: Bool
        public let isNullable: Bool

        public init(
            name: String,
            referenceColumn: String = Configuration.namingStrategy.referenceColumn,
            isUnique: Bool = false,
            isNullable: Bool = true
        ) {
            self.name = name

            if referenceColumn.isEmpty {
                self.referenceColumn = Configuration.namingStrategy.referenceColumn
            } else {
                self.referenceColumn = referenceColumn
            }

            self.isUnique = isUnique
            self.isNullable = isNullable
        }

        public init(stringLiteral name: StringLiteralType) {
            self.init(name: name)
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name && lhs.referenceColumn == rhs.referenceColumn
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(referenceColumn)
        }
    }
}
