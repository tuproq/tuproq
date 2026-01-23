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

            let values = values.map { value in
                var raw = "\(value.0)"

                if let value = value.1 {
                    if value as AnyObject is NSNull {
                        raw += " = NULL"
                    } else if let bool = value as? Bool {
                        raw += " = \(bool)"
                    } else if let character = value as? Character {
                        raw += " = '\(character)'"
                    } else if let data = value as? Data {
                        raw += " = '\(String(data: data, encoding: .utf8) ?? "")'"
                    } else if let date = value as? Date {
                        raw += " = '\(date)'"
                    } else if let double = value as? Double {
                        raw += " = \(double)"
                    } else if let float = value as? Float {
                        raw += " = \(float)"
                    } else if let decimal = value as? Decimal {
                        raw += " = \(decimal)"
                    } else if let int8 = value as? Int8 {
                        raw += " = \(int8)"
                    } else if let int16 = value as? Int16 {
                        raw += " = \(int16)"
                    } else if let int32 = value as? Int32 {
                        raw += " = \(int32)"
                    } else if let int64 = value as? Int64 {
                        raw += " = \(int64)"
                    } else if let int = value as? Int {
                        raw += " = \(int)"
                    } else if let string = value as? String {
                        raw += " = '\(string)'"
                    } else if let uint8 = value as? UInt8 {
                        raw += " = \(uint8)"
                    } else if let uint16 = value as? UInt16 {
                        raw += " = \(uint16)"
                    } else if let uint32 = value as? UInt32 {
                        raw += " = \(uint32)"
                    } else if let uint64 = value as? UInt64 {
                        raw += " = \(uint64)"
                    } else if let uint = value as? UInt {
                        raw += " = \(uint)"
                    } else if let url = value as? URL {
                        raw += " = '\(url.absoluteString)'"
                    } else if let uuid = value as? UUID {
                        raw += " = '\(uuid.uuidString)'"
                    } else {
                        raw += " = '\(value)'"
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
