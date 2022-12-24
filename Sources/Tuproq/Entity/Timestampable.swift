import Foundation

public protocol Timestampable {
    var createdDate: Date { get }
    var updatedDate: Date? { set get }
}
