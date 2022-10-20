public struct IDMapping<Source: Entity>: Hashable {
    public let name: PartialKeyPath<Source>
    public let type: FieldType
    public let column: String

    public init(name: PartialKeyPath<Source> = \.id, type: FieldType = .id(), column: String) {
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
