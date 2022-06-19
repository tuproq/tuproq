import Foundation

public protocol Entity: AnyObject, Codable, Equatable {
    associatedtype Identifiable: Codable, Hashable
    var id: Identifiable { get }

    static var entity: String { get }
}

public extension Entity {
    static var entity: String { String(describing: Self.self) }

    static func == (lhs: Self, rhs: Self) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs) || lhs.id == rhs.id
    }
}
