import Foundation

@propertyWrapper
public final class Observed<V: Codable & Sendable>: Codable, Locking, @unchecked Sendable {
    let lock = NSLock()

    private let name: String?
    private let originalValue: V

    private var _wrappedValue: V
    private weak var entityChangeTracker: EntityChangeTracker?

    public var wrappedValue: V {
        get {
            withLock { _wrappedValue }
        }
        set {
            lock.lock()
            _wrappedValue = newValue
            lock.unlock()
        }
    }

    public init(wrappedValue: V) {
        name = nil
        originalValue = wrappedValue
        _wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        originalValue = try container.decode(V.self)
        _wrappedValue = originalValue
        name = decoder.codingPath.last?.stringValue
        entityChangeTracker = decoder.userInfo[.entityChangeTracker] as? EntityChangeTracker
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
            let storage = entity[keyPath: storageKeyPath]
            storage.lock.lock()
            let oldValue = storage.originalValue
            storage._wrappedValue = newValue
            let entityChangeTracker = storage.entityChangeTracker
            storage.lock.unlock()

            guard let name = storage.name else { return }
            entityChangeTracker?.updateProperty(
                name,
                entity: entity,
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
