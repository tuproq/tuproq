public enum IDGeneratorStrategy: Hashable, Sendable {
    case auto
    case custom(_ type: FieldType)
}
