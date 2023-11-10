import Foundation

@propertyWrapper
public final class Observed<V: Codable>: Codable {
    private weak var entityManager: (any EntityManager)?
    private let name: String?
    private let originalValue: V
    public var wrappedValue: V

    public init(wrappedValue: V) {
        name = nil
        originalValue = wrappedValue
        self.wrappedValue = originalValue
    }

    public init(from decoder: Decoder) throws {
        entityManager = decoder.userInfo[.entityManager] as? (any EntityManager)
        name = decoder.codingPath.last?.stringValue
        originalValue = try decoder.singleValueContainer().decode(V.self)
        wrappedValue = originalValue
    }

    public static subscript<E: Entity>(
        _enclosingInstance entity: E,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<E, V>,
        storage storageKeyPath: ReferenceWritableKeyPath<E, Observed>
    ) -> V {
        get {
            entity[keyPath: storageKeyPath].wrappedValue
        }
        set {
            guard let name = entity[keyPath: storageKeyPath].name else { return }
            let oldValue = entity[keyPath: storageKeyPath].originalValue
            entity[keyPath: storageKeyPath].wrappedValue = newValue
            entity[keyPath: storageKeyPath].entityManager?.propertyChanged(
                entity: entity,
                propertyName: name,
                oldValue: oldValue,
                newValue: newValue
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}
