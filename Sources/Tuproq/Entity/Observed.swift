@propertyWrapper
public final class Observed<V: Codable>: Codable {
    private let name: String?
    private let originalValue: V

    public var wrappedValue: V
    private weak var entityManager: (any EntityManager)?

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

            Task {
                await entity[keyPath: storageKeyPath].entityManager?.propertyValueChanged(
                    entity,
                    name: name,
                    oldValue: oldValue,
                    newValue: newValue
                )
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}
