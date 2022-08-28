public struct IDMapping: Hashable {
    public let name: String
    public let type: FieldType
    public let column: String

    public init(name: String, type: FieldType = .id(), column: String? = nil) {
        self.name = name
        self.type = type
        self.column = column ?? name
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name || lhs.column == rhs.column
    }
}
