@testable import Tuproq
import XCTest

final class SelectSQLExpressionTests: XCTestCase {
    func testInit() {
        // Act
        let expression = SelectSQLExpression()

        // Assert
        XCTAssertTrue(expression.columns.isEmpty)
        XCTAssertEqual(expression.raw, "\(SQLExpression.Kind.select) \(SQLExpression.Kind.star)")
        XCTAssertEqual(expression.raw, expression.description)
    }

    func testInitWithColumns() {
        // Arrange
        let columns: [ColumnSQLExpression] = ["column1", "column2"]

        // Act
        let expression = SelectSQLExpression(columns: columns)

        // Assert
        XCTAssertEqual(expression.columns, columns)
        XCTAssertEqual(
            expression.raw,
            "\(SQLExpression.Kind.select) \(columns.map({ $0.description }).joined(separator: ", "))"
        )
        XCTAssertEqual(expression.raw, expression.description)
    }
}
