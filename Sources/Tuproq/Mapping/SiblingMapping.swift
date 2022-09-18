public struct SiblingMapping: Hashable {
    public let name: String
    public let column: String
    let mapping: AnyEntityMapping
    public let joinTable: String

    public init<M: EntityMapping>(name: String, mapping: M, column: String? = nil, through joinTable: String) {
        self.name = name
        self.mapping = AnyEntityMapping(mapping)
        self.column = column ?? name
        self.joinTable = joinTable
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
