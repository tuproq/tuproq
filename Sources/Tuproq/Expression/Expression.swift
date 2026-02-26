public protocol Expression: CustomStringConvertible, Equatable {
    var raw: String { get }
}

extension Expression {
    public var description: String { raw }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.raw == rhs.raw
    }
}
