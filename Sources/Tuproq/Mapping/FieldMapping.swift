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
