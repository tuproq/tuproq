extension Entity {
    public typealias ID<V: Codable> = IDProperty<Self, V>
}

@propertyWrapper
public final class IDProperty<E: Entity, V: Codable>: FieldProperty<E, V> {
    public override var wrappedValue: V {
        get { super.wrappedValue }
        set { super.wrappedValue = newValue }
    }

    public override init(_ name: String) {
        super.init(name)
    }

    public override init(_ name: String, type: `Type`) {
        super.init(name, type: type)
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
