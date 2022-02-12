@testable import Tuproq
import XCTest

final class OrSQLExpressionTests: XCTestCase {
    func testInit() {
        // Arrange
        let condition = "column > 1"

        // Act
        let expression = OrSQLExpression(condition: condition)

        // Assert
        XCTAssertEqual(expression.condition, condition)
        XCTAssertEqual(expression.raw, "\(SQLExpression.Kind.or) \(condition)")
        XCTAssertEqual(expression.raw, expression.description)
    }
}
