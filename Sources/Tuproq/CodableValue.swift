import Foundation

public enum CodableValue: Codable, Hashable, Sendable {
    case string(String)
    case bool(Bool)
    case int(Int64)
    case uint(UInt64)
    case double(Double)
    case decimal(Decimal)
    case date(Date)
    case uuid(UUID)
    case data(Data)
    case url(URL)
    case array([Self])
    case dictionary([String: Self])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard !container.decodeNil() else {
            self = .null
            return
        }

        if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int64.self) {
            self = .int(int)
        } else if let uint = try? container.decode(UInt64.self) {
            self = .uint(uint)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let decimal = try? container.decode(Decimal.self) {
            self = .decimal(decimal)
        } else if let date = try? container.decode(Date.self) {
            self = .date(date)
        } else if let uuid = try? container.decode(UUID.self) {
            self = .uuid(uuid)
        } else if let data = try? container.decode(Data.self) {
            self = .data(data)
        } else if let url = try? container.decode(URL.self) {
            self = .url(url)
        } else if let dictionary = try? container.decode([String: Self].self) {
            self = .dictionary(dictionary)
        } else if let array = try? container.decode([Self].self) {
            self = .array(array)
        } else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unsupported Codable type"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let string): try container.encode(string)
        case .bool(let bool): try container.encode(bool)
        case .int(let int): try container.encode(int)
        case .uint(let uint): try container.encode(uint)
        case .double(let double): try container.encode(double)
        case .decimal(let decimal): try container.encode(decimal)
        case .date(let date): try container.encode(date)
        case .uuid(let uuid): try container.encode(uuid)
        case .data(let data): try container.encode(data)
        case .url(let url): try container.encode(url)
        case .array(let array): try container.encode(array)
        case .dictionary(let dictionary): try container.encode(dictionary)
        case .null: try container.encodeNil()
        }
    }
}
