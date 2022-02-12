public protocol Entity: Codable, Equatable {
    associatedtype ID: Codable, Hashable
    var id: ID { get }
}

extension Entity {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
