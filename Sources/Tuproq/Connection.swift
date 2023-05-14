import Foundation

public protocol Connection {
    var driver: DatabaseDriver { get }

    @discardableResult
    func open() async throws -> Self
    func close() async throws
    @discardableResult
    func query(_ string: String) async throws -> Data?
}
