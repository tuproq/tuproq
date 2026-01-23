import Foundation

@propertyWrapper
public final class Observed<V: Codable & Sendable>: Codable, @unchecked Sendable {
    private let name: String?
    private let originalValue: V
    private let lock = NSLock()

    private var _wrappedValue: V
    private weak var _entityManager: (any EntityManager)?

    public var wrappedValue: V {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _wrappedValue
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
        _entityManager = decoder.userInfo[.entityManager] as? (any EntityManager)
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
            let entityManager = storage._entityManager
            storage.lock.unlock()

            guard let name = storage.name else { return }
            entityManager?.propertyValueChanged(
                entity,
                name: name,
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
