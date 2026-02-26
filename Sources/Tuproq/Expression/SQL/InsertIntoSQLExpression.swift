import Foundation

final class InsertIntoSQLExpression: SQLExpression, @unchecked Sendable {
    let table: String
    let columns: [String]
    let values: [Any?]

    init(
        table: String,
        columns: [String],
        values: [Any?]
    ) {
        self.table = table
        self.columns = columns
        self.values = values

        var raw = "\(Kind.insertInto) \(table)"
        raw += " (\(columns.joined(separator: ", ")))"

        let placeholders = (1...values.count)
            .map { "{\($0)}" }
            .joined(separator: ", ")
        raw += " \(Kind.values) (\(placeholders))"

        super.init(raw: raw)
    }
}
