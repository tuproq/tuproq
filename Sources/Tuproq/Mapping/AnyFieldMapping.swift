public protocol AnyFieldMapping: Hashable {
    var name: String { get }
}

public extension AnyFieldMapping {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
