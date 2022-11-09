public struct IDMapping: AnyMapping {
    public let field: String
    public let type: FieldType
    public let column: String

    public init(field: String = "id", type: FieldType = .id(), column: String) {
        self.field = field
        self.type = type
        self.column = column
    }
}
