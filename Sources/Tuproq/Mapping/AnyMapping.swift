public protocol AnyMapping: Hashable {
    var field: String { get }
}

public extension AnyMapping {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.field == rhs.field
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(field)
    }
}
