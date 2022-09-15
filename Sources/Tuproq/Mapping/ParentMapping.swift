public struct ParentMapping: Hashable {
    public let name: String
    let parent: AnyEntityMapping
    public let column: String
    public let isUnique: Bool
    public let isNullable: Bool

    public init<M: EntityMapping>(
        name: String,
        parent: M,
        column: String? = nil,
        isUnique: Bool = false,
        isNullable: Bool = false
    ) {
        self.name = name
        self.parent = AnyEntityMapping(parent)
        self.column = column ?? name
        self.isUnique = isUnique
        self.isNullable = isNullable
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
