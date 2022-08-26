public struct IDMapping: Hashable {
    public let name: String
    public let column: String
    public let type: Kind

    public init(name: String, type: Kind, column: String? = nil) {
        self.name = name
        self.type = type
        self.column = column ?? name
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name || lhs.column == rhs.column
    }
}

public extension IDMapping {
    enum Kind: String {
        case integer
        case uuid
    }
}
