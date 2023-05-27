import Collections

public struct Configuration {
    public static var defaultIDField = "id"
    public static var namingStrategy: NamingStrategy = SnakeCaseNamingStrategy()
    var mappings: OrderedDictionary<String, any EntityMapping> { _mappings }
    private var _mappings = OrderedDictionary<String, any EntityMapping>()
    var joinColumnTypes = [String: String]()

    public init() {}

    public mutating func addMapping<M: EntityMapping>(_ mapping: M) {
        let entityName = Self.entityName(from: mapping)
        _mappings[entityName] = mapping
    }

    static func entityName<E: Entity>(from entity: E) -> String {
        String(describingNestedType: E.self)
    }

    static func entityName<E: Entity>(from entityType: E.Type) -> String {
        String(describingNestedType: entityType)
    }

    static func entityName(from entityType: any Entity.Type) -> String {
        String(describingNestedType: entityType)
    }

    static func entityName<M: EntityMapping>(from mapping: M) -> String {
        String(describingNestedType: M.E.self)
    }

    func mapping<E: Entity>(from entity: E) -> (any EntityMapping)? {
        _mappings[Self.entityName(from: entity)]
    }

    func mapping<E: Entity>(from entityType: E.Type) -> (any EntityMapping)? {
        _mappings[Self.entityName(from: entityType)]
    }

    func mapping(from entityType: any Entity.Type) -> (any EntityMapping)? {
        _mappings[Self.entityName(from: entityType)]
    }

    func mapping(from entityName: String) -> (any EntityMapping)? {
        _mappings[entityName]
    }
}
