import Foundation

public extension String {
    enum LetterCase {
        case lower
        case upper
    }
}

extension String {
    func snakeCase(_ letterCase: LetterCase = .lower) -> String {
        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let fullWordsPattern = "([a-z])([A-Z]|[0-9])"
        let digitsFirstPattern = "([0-9])([A-Z])"
        let result = snakeCase(with: acronymPattern)?
            .snakeCase(with: fullWordsPattern)?
            .snakeCase(with:digitsFirstPattern)

        switch letterCase {
        case .lower: return result?.lowercased() ?? lowercased()
        case .upper: return result?.uppercased() ?? uppercased()
        }
    }

    private func snakeCase(with pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: count)

        return regex?.stringByReplacingMatches(
            in: self,
            range: range,
            withTemplate: "$1_$2"
        )
    }
}

extension String {
    var lowercasingFirst: String { prefix(1).lowercased() + dropFirst() }
    var uppercasingFirst: String { prefix(1).uppercased() + dropFirst() }

    var camelCased: String {
        guard !isEmpty else { return "" }
        let parts = components(separatedBy: .alphanumerics.inverted)
        let first = parts.first!.lowercasingFirst
        let rest = parts.dropFirst().map { $0.uppercasingFirst }

        return ([first] + rest).joined()
    }
}

extension String {
    init<T>(describingNestedType: T) {
        self = .init(reflecting: describingNestedType)
            .split(separator: ".")
            .dropFirst()
            .joined(separator: "")
    }
}

extension String {
    var trimmingQuotes: String { trimmingCharacters(in: .init(charactersIn: "\"")) }
}
