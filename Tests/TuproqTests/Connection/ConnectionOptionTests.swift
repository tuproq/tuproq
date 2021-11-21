@testable import Tuproq
import XCTest

final class ConnectionOptionTests: XCTestCase {
    let driver = Driver.postgresql
    let host = "localhost"
    let port = 5432
    let username = "username"
    let password = "password"
    let database = "database"

    func testInit() {
        // Act
        let option = Connection.Option(
            driver: driver,
            host: host,
            username: username,
            password: password,
            database: database
        )

        // Assert
        XCTAssertEqual(option.driver, driver)
        XCTAssertEqual(option.host, host)
        XCTAssertEqual(option.port, port)
        XCTAssertEqual(option.username, username)
        XCTAssertEqual(option.password, password)
        XCTAssertEqual(option.database, database)
    }

    func testInitWithURL() {
        // Arrange
        var url = URL(string: "\(driver)://\(username):\(password)@\(host):\(port)/\(database)")!

        // Act
        var option = Connection.Option(url: url)!

        // Assert
        XCTAssertEqual(option.driver, driver)
        XCTAssertEqual(option.host, host)
        XCTAssertEqual(option.port, port)
        XCTAssertEqual(option.username, username)
        XCTAssertEqual(option.password, password)
        XCTAssertEqual(option.database, database)

        // Arrange
        url = URL(string: "\(driver):")!

        // Act
        option = Connection.Option(url: url)!

        // Assert
        XCTAssertEqual(option.driver, driver)
        XCTAssertEqual(option.host, Connection.Option.defaultHost)
        XCTAssertEqual(option.port, driver.port)
        XCTAssertNil(option.username)
        XCTAssertNil(option.password)
        XCTAssertNil(option.database)
    }

    func testInitWithInvalidDriver() {
        // Arrange
        let url = URL(string: "invalid:")!

        // Act
        let option = Connection.Option(url: url)

        // Assert
        XCTAssertNil(option)
    }
}
