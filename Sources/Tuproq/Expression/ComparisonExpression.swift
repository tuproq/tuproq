final class ComparisonExpression: Expression {
    let type: Kind
    var raw: String { type.rawValue }

    init(_ type: Kind) {
        self.type = type
    }
}

extension ComparisonExpression {
    enum Kind: String, CustomStringConvertible {
        case equal = "="
        case greaterThan = ">"
        case greaterThanOrEqual = ">="
        case lessThan = "<"
        case lessThanOrEqual = "<="
        case notEqual = "!="

        var description: String { rawValue }
    }
}
