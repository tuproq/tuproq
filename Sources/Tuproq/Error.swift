import Foundation

public struct TuproqError: LocalizedError {
    let message: String
    public var errorDescription: String? { message }

    init(_ errorType: ErrorType) {
        self.init(errorType.message)
    }

    init(_ message: String? = nil) {
        let errorType = String(describing: type(of: self))

        if let message = message, !message.isEmpty {
            self.message = "\(errorType): \(message)"
        } else {
            self.message = "\(errorType): \(ErrorType.unknown)"
        }
    }
}

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
