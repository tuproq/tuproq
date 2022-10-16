public struct JoinTable {
    public let name: String
    public let column: Column
    public let inverseColumn: Column
}

extension JoinTable {
    public struct Column: ExpressibleByStringLiteral {
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
    }
}
