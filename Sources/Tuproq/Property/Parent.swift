extension Entity {
    public typealias Parent<V: Codable> = ParentProperty<Self, V>
}

@propertyWrapper
public final class ParentProperty<E: Entity, V: Codable>: FieldProperty<E, V> {
    public override var wrappedValue: V {
        get { super.wrappedValue }
        set { super.wrappedValue = newValue }
    }

    public init() {
        super.init(name: "")
    }

    public override init(name: String) {
        super.init(name: name)
    }

    public override init(name: String, type: `Type`) {
        super.init(name: name, type: type)
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
