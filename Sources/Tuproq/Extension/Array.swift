import Foundation

public extension Array {
    func decode<E: Entity>() throws -> [E] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try JSONSerialization.data(withJSONObject: self)

        return try decoder.decode([E].self, from: data)
    }
}
