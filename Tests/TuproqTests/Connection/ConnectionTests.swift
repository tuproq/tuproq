@testable import Tuproq
import XCTest

final class ConnectionTests: XCTestCase {
    func testInit() {
        // Arrange
        let option = Connection.Option(driver: .postgresql)

        // Act
        let connection = Connection(option: option)

        // Assert
        XCTAssertEqual(connection.name, Connection.defaultName)
        XCTAssertEqual(connection.option, option)
    }

    func testEquality() {
        // Arrange
        let option1 = Connection.Option(driver: .mysql)
        let option2 = Connection.Option(driver: .postgresql)

        // Act
        let connection1 = Connection(option: option1)
        let connection2 = Connection(option: option2)

        // Assert
        XCTAssertEqual(connection1, connection2)
    }
}
