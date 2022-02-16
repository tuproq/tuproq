@testable import Tuproq
import XCTest

final class OrderBySQLExpressionTests: XCTestCase {
    func testInit() {
        // Arrange
        let columns: [(String, SQLExpression.Sorting)] = [("column1", .asc), ("column2", .desc)]

        // Act
        let expression = OrderBySQLExpression(columns: columns)

        // Assert
        XCTAssertEqual(expression.raw, "\(SQLExpression.Kind.orderBy) column1 ASC, column2 DESC")
        XCTAssertEqual(expression.raw, expression.description)
    }
}
