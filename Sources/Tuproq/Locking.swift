import Foundation

protocol Locking {
    var lock: NSLock { get }
}

extension Locking {
    @inline(__always)
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }

        return try body()
    }
}
