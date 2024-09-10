public struct IDMapping: AnyFieldMapping {
    public let name: String
    public let type: FieldType
    public let column: String

    public init(
        _ name: String = "",
        type: FieldType = .id(),
        column: String = ""
    ) {
        self.name = name.isEmpty ? Configuration.defaultIDField : name
        self.type = type
        self.column = column.isEmpty ? Configuration.namingStrategy.column(field: self.name) : column
    }
}
