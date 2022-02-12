@testable import Tuproq
import XCTest

final class AndSQLExpressionTests: XCTestCase {
    func testInit() {
        // Arrange
        let condition = "column = 1"

        // Act
        let expression = AndSQLExpression(condition: condition)

        // Assert
        XCTAssertEqual(expression.condition, condition)
        XCTAssertEqual(expression.raw, "\(SQLExpression.Kind.and) \(condition)")
        XCTAssertEqual(expression.raw, expression.description)
    }
}
