public enum DatabaseDriver: String {
    case mysql, postgresql

    public var port: Int {
        switch self {
        case .mysql: return 3306
        case .postgresql: return 5432
        }
    }
}
