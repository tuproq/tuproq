public struct IDMapping: AnyMapping {
    public let field: String
    public let type: FieldType
    public let column: String

    public init(field: String = Configuration.defaultIDField, type: FieldType = .id(), column: String? = nil) {
        if field.isEmpty {
            self.field = Configuration.defaultIDField
        } else {
            self.field = field
        }

        self.type = type

        if let column = column, !column.isEmpty {
            self.column = column
        } else {
            self.column = Configuration.namingStrategy.column(field: self.field)
        }
    }
}
