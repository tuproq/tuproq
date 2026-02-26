import Foundation

final class UpdateSQLExpression: SQLExpression, @unchecked Sendable {
    let table: String
    let values: [(String, Any?)]

    init(
        table: String,
        values: [(String, Any?)]
    ) {
        self.table = table
        self.values = values
        var raw = "\(Kind.update) \(table)"

        if !values.isEmpty {
            raw += " \(Kind.set)"

            let values = (0..<values.count)
                .map { "\(values[$0].0) = {\($0 + 1)}"}
                .joined(separator: ", ")
            raw += " \(values)"
        }

        super.init(raw: raw)
    }
}
