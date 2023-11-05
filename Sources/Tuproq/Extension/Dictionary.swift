import Foundation

extension Dictionary {
    func decode<E: Entity>(to entityType: E.Type, entityID: AnyHashable) throws -> E {
        let dateFormatter = DateFormatter.iso8601

        let dictionary: [Self.Key: Any?] = mapValues { value in
            if let date = value as? Date {
                return dateFormatter.string(from: date)
            } else if let uuid = value as? UUID {
                return uuid.uuidString
            }

            return value
        }
        let data = try JSONSerialization.data(withJSONObject: dictionary)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        if let dictionary = dictionary as? [String: Any?] {
            let id = dictionary["id"] as? AnyHashable ?? entityID
            decoder.userInfo = [
                CodingUserInfoKey(rawValue: "entityName")!: String(describingNestedType: entityType),
                CodingUserInfoKey(rawValue: "entityID")!: id
            ]
        }

        return try decoder.decode(entityType, from: data)
    }

    public func decode<E: Entity>() throws -> E {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try JSONSerialization.data(withJSONObject: self)

        return try decoder.decode(E.self, from: data)
    }
}
