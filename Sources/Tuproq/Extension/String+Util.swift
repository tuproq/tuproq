import Foundation

public extension String {
    enum LetterCase {
        case lower
        case upper
    }
}

extension String {
    var droppingLeadingSlash: String {
        first == "/" ? String(dropFirst()) : self
    }

    var droppingLeadingUnderscore: String {
        first == "_" ? String(dropFirst()) : self
    }

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
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)

        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
    }
}
