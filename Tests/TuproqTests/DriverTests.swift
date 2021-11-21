@testable import Tuproq
import XCTest

final class DriverTests: XCTestCase {
    func testCases() {
        // Assert
        XCTAssertEqual(Driver.mysql.rawValue, "mysql")
        XCTAssertEqual(Driver.mysql.port, 3306)
        XCTAssertEqual(Driver.postgresql.rawValue, "postgresql")
        XCTAssertEqual(Driver.postgresql.port, 5432)
    }
}
