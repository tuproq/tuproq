import Foundation

extension Dictionary {
    func decode<E: Entity>(to entityType: E.Type, entityManager: any EntityManager) throws -> E {
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
        decoder.userInfo = [
            .entityManager: entityManager,
            .entityName: Configuration.entityName(from: entityType)
        ]

        return try decoder.decode(entityType, from: data)
    }
}
