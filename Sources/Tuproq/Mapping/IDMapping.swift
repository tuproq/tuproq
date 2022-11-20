public struct IDMapping: AnyFieldMapping {
    public let field: String
    public let type: FieldType
    public let column: String

    public init(field: String = "", type: FieldType = .id(), column: String = "") {
        if field.isEmpty {
            self.field = Configuration.defaultIDField
        } else {
            self.field = field
        }

        self.type = type

        if column.isEmpty {
            self.column = Configuration.namingStrategy.column(field: self.field)
        } else {
            self.column = column
        }
    }
}
