@testable import Tuproq
import XCTest

final class WhereSQLExpressionTests: XCTestCase {
    func testInit() {
        // Arrange
        let condition = "column != 1"

        // Act
        let expression = WhereSQLExpression(condition: condition)

        // Assert
        XCTAssertEqual(expression.condition, condition)
        XCTAssertEqual(expression.raw, "\(SQLExpression.Kind.where) \(condition)")
        XCTAssertEqual(expression.raw, expression.description)
    }
}
