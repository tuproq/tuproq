import Foundation

public protocol Entity: AnyObject, Codable, Hashable {
    associatedtype Identifiable: Codable, Hashable
    var id: Identifiable { get }

    static var entity: String { get }
}

public extension Entity {
    static var entity: String { String(describing: Self.self) }

    static func == (lhs: Self, rhs: Self) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs) || lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        if id as AnyObject is NSNull {
            hasher.combine(ObjectIdentifier(self))
        } else {
            hasher.combine(id)
        }
    }
}
