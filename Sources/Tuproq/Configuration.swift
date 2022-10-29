import Collections

public struct Configuration {
    public static var namingStrategy: NamingStrategy = SnakeCaseNamingStrategy()
    var mappings: OrderedDictionary<String, AnyEntityMapping> { _mappings }
    private var _mappings = OrderedDictionary<String, AnyEntityMapping>()
    var joinColumnTypes = [String: String]()

    public init() {}

    public mutating func addMapping<M: EntityMapping>(_ mapping: M) {
        let entityName = Self.entityName(from: mapping)
        _mappings[entityName] = AnyEntityMapping(mapping)
    }

    static func entityName<E: Entity>(from entity: E) -> String {
        String(describing: E.self)
    }

    static func entityName<E: Entity>(from entityType: E.Type) -> String {
        String(describing: entityType)
    }

    static func entityName(from entityType: AnyEntity.Type) -> String {
        String(describing: entityType)
    }

    static func entityName<M: EntityMapping>(from mapping: M) -> String {
        String(describing: M.E.self)
    }

    func mapping<E: Entity>(from entity: E) -> AnyEntityMapping? {
        _mappings[Self.entityName(from: entity)]
    }

    func mapping<E: Entity>(from entityType: E.Type) -> AnyEntityMapping? {
        _mappings[Self.entityName(from: entityType)]
    }

    func mapping(from entityType: AnyEntity.Type) -> AnyEntityMapping? {
        _mappings[Self.entityName(from: entityType)]
    }
}
