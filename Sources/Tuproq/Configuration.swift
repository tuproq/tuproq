import Collections

public struct Configuration {
    public static var namingStrategy: NamingStrategy = SnakeCaseNamingStrategy()
    private(set) var mappings = OrderedDictionary<String, AnyEntityMapping>()
    var joinColumnTypes = [String: String]()

    public init() {}

    public mutating func addMapping<M: EntityMapping>(_ mapping: M) {
        mappings[String(describing: mapping.entity)] = AnyEntityMapping(mapping)
    }
}
