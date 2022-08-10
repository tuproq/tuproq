import Foundation

extension String {
    var droppingLeadingSlash: String {
        first == "/" ? String(dropFirst()) : self
    }

    var snakeCased: String {
        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let fullWordsPattern = "([a-z])([A-Z]|[0-9])"
        let digitsFirstPattern = "([0-9])([A-Z])"

        return snakeCase(with: acronymPattern)?
            .snakeCase(with: fullWordsPattern)?
            .snakeCase(with:digitsFirstPattern)?.lowercased() ?? lowercased()
    }

    private func snakeCase(with pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)

        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
    }
}
