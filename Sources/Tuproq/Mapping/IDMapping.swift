public struct IDMapping: Hashable {
    public let name: String
    public let column: String
    public let type: Kind

    public init(name: String, column: String? = nil, type: Kind) {
        self.name = name
        self.column = column ?? name
        self.type = type
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
