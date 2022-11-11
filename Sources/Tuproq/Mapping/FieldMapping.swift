public struct FieldMapping: AnyFieldMapping {
    public let field: String
    public let type: FieldType
    public let column: Column

    public init(field: String, type: FieldType) {
        self.init(field: field, type: type, column: "")
    }

    public init(field: String, type: FieldType, isUnique: Bool = false, isNullable: Bool = true) {
        self.init(
            field: field,
            type: type,
            column: .init(name: "", isUnique: isUnique, isNullable: isNullable)
        )
    }

    public init(field: String, type: FieldType, column: Column) {
        self.field = field
        self.type = type

        if column.name.isEmpty {
            self.column = .init(
                name: Configuration.namingStrategy.column(field: self.field),
                isUnique: column.isUnique,
                isNullable: column.isNullable
            )
        } else {
            self.column = column
        }
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
