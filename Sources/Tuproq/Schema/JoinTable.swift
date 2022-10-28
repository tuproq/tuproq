public struct JoinTable {
    public let name: String
    public let columns: Set<Column>
    public let inverseColumns: Set<Column>

    public init(name: String, columns: Set<Column>, inverseColumns: Set<Column>) {
        self.name = name
        self.columns = columns
        self.inverseColumns = inverseColumns
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
            self.referenceColumn = referenceColumn
            self.isUnique = isUnique
            self.isNullable = isNullable
        }

        public init(stringLiteral name: StringLiteralType) {
            self.name = name
            referenceColumn = Configuration.namingStrategy.referenceColumn
            isUnique = false
            isNullable = true
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
