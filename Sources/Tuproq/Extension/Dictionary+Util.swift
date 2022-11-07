import Foundation

extension Dictionary {
    func decode<E: Entity>(to entityType: E.Type) throws -> E {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

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

        if let dictionary = dictionary as? [String: Any?], let id = dictionary["id"] as? AnyHashable {
            decoder.userInfo = [CodingUserInfoKey(rawValue: "id")!: id]
        }

        return try decoder.decode(entityType, from: data)
    }
}
