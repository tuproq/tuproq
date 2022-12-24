import Foundation

public protocol Timestampable {
    var createdDate: Date { set get }
    var updatedDate: Date? { set get }
}
