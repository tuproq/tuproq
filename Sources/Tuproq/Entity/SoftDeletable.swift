import Foundation

public protocol SoftDeletable {
    var deletedDate: Date? { set get }
}
