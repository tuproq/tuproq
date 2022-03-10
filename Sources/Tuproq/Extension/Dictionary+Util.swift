import Foundation

extension Dictionary {
    func decode<E: Entity>(to entityType: E.Type) throws -> E {
        let data = try JSONSerialization.data(withJSONObject: self)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        if let dictionary = self as? [String: Any?], let id = dictionary["id"] as? AnyHashable {
            decoder.userInfo = [CodingUserInfoKey(rawValue: "id")!: id]
        }

        return try decoder.decode(entityType, from: data)
    }
}
