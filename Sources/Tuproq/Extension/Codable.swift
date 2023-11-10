import Foundation

extension Encodable {
    func asDictionary() throws -> [String: Any?] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

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
