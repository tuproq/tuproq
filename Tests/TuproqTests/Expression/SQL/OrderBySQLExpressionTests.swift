@testable import Tuproq
import XCTest

final class OrderBySQLExpressionTests: XCTestCase {
    func testInit() {
        // Arrange
        let columns: [(String, Bool)] = [("column1", true), ("column2", false)]

        // Act
        let expression = OrderBySQLExpression(columns: columns)

        // Assert
        XCTAssertEqual(expression.raw, "\(SQLExpression.Kind.orderBy) column1 ASC, column2 DESC")
        XCTAssertEqual(expression.raw, expression.description)
    }
}
