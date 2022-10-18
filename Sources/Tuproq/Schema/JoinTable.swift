public struct JoinTable {
    public let name: String
    public let columns: Set<Column>
    public let inverseColumns: Set<Column>
}

extension JoinTable {
    public struct Column: ExpressibleByStringLiteral, Hashable {
        public let name: String
        public let referencedColumnName: String
        public let isUnique: Bool
        public let isNullable: Bool

        public init(
            name: String,
            referencedColumnName: String = "id",
            isUnique: Bool = false,
            isNullable: Bool = true
        ) {
            self.name = name
            self.referencedColumnName = referencedColumnName
            self.isUnique = isUnique
            self.isNullable = isNullable
        }

        public init(stringLiteral name: StringLiteralType) {
            self.name = name
            referencedColumnName = "id"
            isUnique = false
            isNullable = true
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name && lhs.referencedColumnName == rhs.referencedColumnName
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(referencedColumnName)
        }
    }
}
