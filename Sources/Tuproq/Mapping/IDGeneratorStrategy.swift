public enum IDGeneratorStrategy: Hashable {
    case auto
    case concrete(type: FieldType)
}
