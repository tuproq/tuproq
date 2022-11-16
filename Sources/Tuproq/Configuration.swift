import Collections

public struct Configuration {
    public static var defaultIDField = "id"
    public static var namingStrategy: NamingStrategy = SnakeCaseNamingStrategy()
    var mappings: OrderedDictionary<String, any EntityMapping> { _mappings }
    private var _mappings = OrderedDictionary<String, any EntityMapping>()
    var joinColumnTypes = [String: String]()
    private var repositories = [String: any EntityRepository]()

    public init() {}

    public mutating func addMapping<M: EntityMapping>(_ mapping: M) {
        let entityName = Self.entityName(from: mapping)
        _mappings[entityName] = mapping
    }

    public mutating func getRepository<R: EntityRepository>(_ entityType: R.E.Type) -> R {
        let entityName = Configuration.entityName(from: entityType)

        if let repository = repositories[entityName] {
            return repository as! R
        }

        let repository = R()
        repositories[entityName] = repository

        return repository
    }

    static func entityName<E: Entity>(from entity: E) -> String {
        String(describing: E.self)
    }

    static func entityName<E: Entity>(from entityType: E.Type) -> String {
        String(describing: entityType)
    }

    static func entityName(from entityType: any Entity.Type) -> String {
        String(describing: entityType)
    }

    static func entityName<M: EntityMapping>(from mapping: M) -> String {
        String(describing: M.E.self)
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
