import class Foundation.NSNull

public protocol Entity: AnyObject, Codable, Hashable {
    associatedtype ID: Codable, Hashable
    var id: ID { get }
}

public extension Entity {
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

public protocol SoftDeletableEntity: Entity, SoftDeletable {}
public protocol TimestampableEntity: Entity, Timestampable {}
public protocol SoftDeletableTimestampableEntity: SoftDeletableEntity, TimestampableEntity {}
