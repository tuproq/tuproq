public protocol AssociationMapping: Hashable {
    associatedtype E: Entity
    var field: PartialKeyPath<E> { get }
}

public extension AssociationMapping {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.field == rhs.field
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(field)
    }
}
