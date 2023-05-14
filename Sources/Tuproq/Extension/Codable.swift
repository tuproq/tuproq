import Foundation

extension Encodable {
    func asDictionary() throws -> [String: Any?] {
        let dateFormatter = DateFormatter.iso8601
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(dateFormatter)

        let data = try encoder.encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(
            with: data,
            options: .fragmentsAllowed
        ) as? [String: Any?] else {
            throw error(.entityToDictionaryFailed)
        }

        return dictionary
    }
}
