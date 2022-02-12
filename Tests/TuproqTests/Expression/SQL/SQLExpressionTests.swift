@testable import Tuproq
import XCTest

final class SQLExpressionTests: XCTestCase {
    func testInit() {
        // Arrange
        let raw = "SELECT * FROM table1 AS t1"

        // Act
        let expression = SQLExpression(raw: raw)

        // Assert
        XCTAssertEqual(expression.raw, raw)
        XCTAssertEqual(expression.raw, expression.description)
    }
}
