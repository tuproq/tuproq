enum ErrorType: CustomStringConvertible {
    case detachedObjectNotPersistable
    case entityToDictionaryFailed
    case unknown

    var description: String { message }

    var message: String {
        switch self {
        case .detachedObjectNotPersistable: return "A detached object is not persistable."
        case .entityToDictionaryFailed: return "Can't encode an entity to a dictionary."
        case .unknown: return "An unknown error."
        }
    }
}
