import Foundation

final class UpdateSQLExpression: SQLExpression {
    let table: String
    let values: [(String, Any?)]

    init(table: String, values: [(String, Any?)]) {
        self.table = table
        self.values = values
        var raw = "\(Kind.update) \(table)"

        if !values.isEmpty {
            raw += " \(Kind.set)"

            let values = values.map { value in
                var raw = "\(value.0)"

                if let value = value.1 {
                    if value as AnyObject is NSNull {
                        raw += " = NULL"
                    } else if let string = value as? String {
                        raw += " = '\(string)'"
                    } else if let url = value as? URL {
                        raw += " = '\(url.absoluteString)'"
                    } else {
                        raw += " = \(value)"
                    }
                } else {
                    raw += " = NULL"
                }

                return raw
            }.joined(separator: ", ")
            raw += " \(values)"
        }

        super.init(raw: raw)
    }
}
