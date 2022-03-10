import Foundation

extension Encodable {
    func asDictionary() throws -> [String: Any?] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        
        let data = try encoder.encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(
            with: data,
            options: .fragmentsAllowed
        ) as? [String: Any?] else {
            throw NSError()
        }

        return dictionary
    }
}
