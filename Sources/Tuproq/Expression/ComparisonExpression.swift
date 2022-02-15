final class ComparisonExpression: Expression {
    let kind: Kind
    var raw: String { kind.rawValue }

    init(kind: Kind) {
        self.kind = kind
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
