import Foundation

final class InsertIntoSQLExpression: SQLExpression, @unchecked Sendable {
    let table: String
    let columns: [String]
    let values: [Any?]

    init(
        table: String,
        columns: [String] = .init(),
        values: [Any?]
    ) {
        self.table = table
        self.columns = columns
        self.values = values
        var raw = "\(Kind.insertInto) \(table)"

        if !columns.isEmpty {
            raw += " (\(columns.map({ $0.description }).joined(separator: ", ")))"
        }

        if !values.isEmpty {
            let values = values.map { value in
                if let value {
                    if value as AnyObject is NSNull {
                        return "NULL"
                    } else if let bool = value as? Bool {
                        return "\(bool)"
                    } else if let character = value as? Character {
                        return "'\(character)'"
                    } else if let data = value as? Data {
                        return "'\(String(data: data, encoding: .utf8) ?? "")'"
                    } else if let date = value as? Date {
                        return "'\(date)'"
                    } else if let double = value as? Double {
                        return "\(double)"
                    } else if let float = value as? Float {
                        return "\(float)"
                    } else if let decimal = value as? Decimal {
                        return "\(decimal)"
                    } else if let int8 = value as? Int8 {
                        return "\(int8)"
                    } else if let int16 = value as? Int16 {
                        return "\(int16)"
                    } else if let int32 = value as? Int32 {
                        return "\(int32)"
                    } else if let int64 = value as? Int64 {
                        return "\(int64)"
                    } else if let int = value as? Int {
                        return "\(int)"
                    } else if let string = value as? String {
                        return "'\(string)'"
                    } else if let uint8 = value as? UInt8 {
                        return "\(uint8)"
                    } else if let uint16 = value as? UInt16 {
                        return "\(uint16)"
                    } else if let uint32 = value as? UInt32 {
                        return "\(uint32)"
                    } else if let uint64 = value as? UInt64 {
                        return "\(uint64)"
                    } else if let uint = value as? UInt {
                        return "\(uint)"
                    } else if let url = value as? URL {
                        return "'\(url.absoluteString)'"
                    } else if let uuid = value as? UUID {
                        return "'\(uuid.uuidString)'"
                    }

                    return "'\(value)'"
                }

                return "\(Kind.null)"
            }.joined(separator: ", ")
            raw += " \(Kind.values) (\(values))"
        }

        super.init(raw: raw)
    }
}
