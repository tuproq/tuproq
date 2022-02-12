@testable import Tuproq
import XCTest

final class HavingSQLExpressionTests: XCTestCase {
    func testInit() {
        // Arrange
        let condition = "SUM(column) < 100"

        // Act
        let expression = HavingSQLExpression(condition: condition)

        // Assert
        XCTAssertEqual(expression.condition, condition)
        XCTAssertEqual(expression.raw, "\(SQLExpression.Kind.having) \(condition)")
        XCTAssertEqual(expression.raw, expression.description)
    }
}
