public struct FieldMapping: AnyFieldMapping {
    public let name: String
    public let type: FieldType
    public let column: Column

    public init(
        _ name: String,
        type: FieldType
    ) {
        self.init(
            name,
            type: type,
            column: ""
        )
    }

    public init(
        _ name: String,
        type: FieldType,
        isUnique: Bool = false,
        isNullable: Bool = true
    ) {
        self.init(
            name,
            type: type,
            column: .init(
                "",
                isUnique: isUnique,
                isNullable: isNullable
            )
        )
    }

    public init(
        _ name: String,
        type: FieldType,
        column: Column
    ) {
        self.name = name
        self.type = type

        if column.name.isEmpty {
            self.column = .init(
                Configuration.namingStrategy.column(field: self.name),
                isUnique: column.isUnique,
                isNullable: column.isNullable
            )
        } else {
            self.column = column
        }
    }
}

extension FieldMapping {
    public struct Column: ExpressibleByStringLiteral, Hashable, Sendable {
        public let name: String
        public let isUnique: Bool
        public let isNullable: Bool

        public init(
            _ name: String,
            isUnique: Bool = false,
            isNullable: Bool = true
        ) {
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
