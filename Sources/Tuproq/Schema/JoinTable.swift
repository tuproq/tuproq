public struct JoinTable: Hashable {
    public let name: String
    public let columns: Set<Column>
    public let inverseColumns: Set<Column>
    public let constraints: Set<ConstraintType>

    public init(
        name: String,
        columns: Set<Column>,
        inverseColumns: Set<Column>,
        constraints: Set<ConstraintType> = .init()
    ) {
        self.name = name
        self.columns = columns
        self.inverseColumns = inverseColumns
        self.constraints = constraints
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
            _ name: String,
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
            self.init(name)
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
