public struct FieldMapping<Source: Entity>: Hashable {
    public let name: PartialKeyPath<Source>
    public let type: FieldType
    public let column: Column

    public init(name: PartialKeyPath<Source>, type: FieldType, column: Column) {
        self.name = name
        self.type = type
        self.column = column
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

extension FieldMapping {
    public struct Column: ExpressibleByStringLiteral, Hashable {
        public let name: String
        public let isNullable: Bool
        public let isUnique: Bool

        public init(name: String, isNullable: Bool = true, isUnique: Bool = false) {
            self.name = name
            self.isNullable = isNullable
            self.isUnique = isUnique
        }

        public init(stringLiteral name: StringLiteralType) {
            self.name = name
            isNullable = true
            isUnique = false
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }
    }
}
