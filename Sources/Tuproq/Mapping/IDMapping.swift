public struct IDMapping: Hashable {
    public let names: [String]
    public let type: FieldType
    public let columns: [String]

    public init(name: String, type: FieldType = .id(), column: String = "") {
        self.names = [name]
        self.type = type
        self.columns = column.isEmpty ? names : [column]
    }

    public init(names: [String], type: FieldType = .id(), columns: [String] = .init()) {
        self.names = names
        self.type = type
        self.columns = columns.isEmpty ? names : columns
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.names == rhs.names
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(names)
    }
}
