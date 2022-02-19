@testable import Tuproq
import XCTest

final class DatabaseDriverTests: XCTestCase {
    func testCases() {
        // Assert
        XCTAssertEqual(DatabaseDriver.mysql.rawValue, "mysql")
        XCTAssertEqual(DatabaseDriver.mysql.port, 3306)
        XCTAssertEqual(DatabaseDriver.postgresql.rawValue, "postgresql")
        XCTAssertEqual(DatabaseDriver.postgresql.port, 5432)
    }
}
