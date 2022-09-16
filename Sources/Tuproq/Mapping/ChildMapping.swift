public struct ChildMapping: Hashable {
    public let name: String
    let child: AnyEntityMapping
    let isMany: Bool

    public init<M: EntityMapping>(name: String, child: M) {
        self.name = name
        self.child = AnyEntityMapping(child)
        isMany = false
    }

    public init<M: EntityMapping>(name: String, children: M) {
        self.name = name
        child = AnyEntityMapping(children)
        isMany = true
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
