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
        if let container = try? decoder.container(keyedBy: DynamicCodingKey.self) {
            var dict: [String: Self] = [:]
            for key in container.allKeys {
                dict[key.stringValue] =
                    try container.decode(Self.self, forKey: key)
            }
            self = .dictionary(dict)
            return
        }

        if var container = try? decoder.unkeyedContainer() {
            var array: [Self] = []
            while !container.isAtEnd {
                array.append(try container.decode(Self.self))
            }
            self = .array(array)
            return
        }

        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
            return
        }

        if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
            return
        }

        if let int = try? container.decode(Int64.self) {
            self = .int(int)
            return
        }

        if let uint = try? container.decode(UInt64.self) {
            self = .uint(uint)
            return
        }

        if let double = try? container.decode(Double.self) {
            self = .double(double)
            return
        }

        if let decimal = try? container.decode(Decimal.self) {
            self = .decimal(decimal)
            return
        }

        if let date = try? container.decode(Date.self) {
            self = .date(date)
            return
        }

        if let uuid = try? container.decode(UUID.self) {
            self = .uuid(uuid)
            return
        }

        if let data = try? container.decode(Data.self) {
            self = .data(data)
            return
        }

        if let url = try? container.decode(URL.self) {
            self = .url(url)
            return
        }

        if let string = try? container.decode(String.self) {
            self = .string(string)
            return
        }

        throw DecodingError.typeMismatch(
            Self.self,
            .init(
                codingPath: decoder.codingPath,
                debugDescription: "Unsupported Codable type"
            )
        )
    }

    public func encode(to encoder: Encoder) throws {

        switch self {

        case .dictionary(let dict):
            var container = encoder.container(keyedBy: DynamicCodingKey.self)
            for (key, value) in dict {
                try container.encode(value, forKey: .init(stringValue: key))
            }

        case .array(let array):
            var container = encoder.unkeyedContainer()
            for value in array {
                try container.encode(value)
            }

        case .string(let v):
            var container = encoder.singleValueContainer()
            try container.encode(v)

        case .bool(let v):
            var container = encoder.singleValueContainer()
            try container.encode(v)

        case .int(let v):
            var container = encoder.singleValueContainer()
            try container.encode(v)

        case .uint(let v):
            var container = encoder.singleValueContainer()
            try container.encode(v)

        case .double(let v):
            var container = encoder.singleValueContainer()
            try container.encode(v)

        case .decimal(let v):
            var container = encoder.singleValueContainer()
            try container.encode(v)

        case .date(let v):
            var container = encoder.singleValueContainer()
            try container.encode(v)

        case .uuid(let v):
            var container = encoder.singleValueContainer()
            try container.encode(v)

        case .data(let v):
            var container = encoder.singleValueContainer()
            try container.encode(v)

        case .url(let v):
            var container = encoder.singleValueContainer()
            try container.encode(v)

        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
}

private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
