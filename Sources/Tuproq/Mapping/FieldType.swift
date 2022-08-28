public indirect enum FieldType: Hashable {
    case bool
    case character
    case data(length: UInt? = nil, isFixed: Bool = false)
    case date
    case decimal(precision: UInt, scale: UInt, isUnsigned: Bool = false)
    case double(isUnsigned: Bool = false)
    case float(isUnsigned: Bool = false)
    case id(strategy: IDGeneratorStrategy = .auto)
    case int8
    case int16
    case int32
    case int64
    case string(length: UInt? = nil, isFixed: Bool = false)
    case uint8
    case uint16
    case uint32
    case uint64
    case uuid
}
