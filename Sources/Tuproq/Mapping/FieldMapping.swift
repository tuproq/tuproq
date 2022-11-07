public struct FieldMapping: Hashable {
    public let field: String
    public let type: FieldType
    public let column: Column

    public init(field: String, type: FieldType, column: Column) {
        self.field = field
        self.type = type
        self.column = column
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.field == rhs.field
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(field)
    }
}

extension FieldMapping {
    public struct Column: ExpressibleByStringLiteral, Hashable {
        public let name: String
        public let isUnique: Bool
        public let isNullable: Bool

        public init(name: String, isUnique: Bool = false, isNullable: Bool = true) {
            self.name = name
            self.isUnique = isUnique
            self.isNullable = isNullable
        }

        public init(stringLiteral name: StringLiteralType) {
            self.name = name
            isUnique = false
            isNullable = true
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }
    }
}
