@testable import Tuproq
import XCTest

final class ReturningSQLExpressionTests: XCTestCase {
    func testInit() {
        // Act
        let expression = ReturningSQLExpression()

        // Assert
        XCTAssertTrue(expression.columns.isEmpty)
        XCTAssertEqual(expression.raw, "\(SQLExpression.Kind.returning) \(SQLExpression.Kind.star)")
        XCTAssertEqual(expression.raw, expression.description)
    }

    func testInitWithColumns() {
        // Arrange
        let columns: [ColumnSQLExpression] = ["column1", "column2"]

        // Act
        let expression = ReturningSQLExpression(columns: columns)

        // Assert
        XCTAssertEqual(expression.columns, columns)
        XCTAssertEqual(
            expression.raw,
            "\(SQLExpression.Kind.returning) \(columns.map({ $0.description }).joined(separator: ", "))"
        )
        XCTAssertEqual(expression.raw, expression.description)
    }
}
