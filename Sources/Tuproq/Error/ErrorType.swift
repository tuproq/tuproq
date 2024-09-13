enum ErrorType: CustomStringConvertible {
    case entityToDictionaryFailed
    case unknown

    var description: String { message }

    var message: String {
        switch self {
        case .entityToDictionaryFailed: "Can't encode an entity to a dictionary."
        case .unknown: "An unknown error."
        }
    }
}
