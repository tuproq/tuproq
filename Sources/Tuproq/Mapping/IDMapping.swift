public struct IDMapping: AnyFieldMapping {
    public let field: String
    public let type: FieldType
    public let column: String

    public init(field: String = "", type: FieldType = .id(), column: String = "") {
        self.field = field.isEmpty ? Configuration.defaultIDField : field
        self.type = type
        self.column = column.isEmpty ? Configuration.namingStrategy.column(field: self.field) : column
    }
}
