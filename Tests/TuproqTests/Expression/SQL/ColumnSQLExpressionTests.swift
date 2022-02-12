@testable import Tuproq
import XCTest

final class ColumnSQLExpressionTests: XCTestCase {
    let column = "column"
    let asKeyword = SQLExpression.Kind.as
    let alias = "c"

    func testInit() {
        // Act
        let expression = ColumnSQLExpression(name: column)

        // Assert
        XCTAssertEqual(expression.name, column)
        XCTAssertNil(expression.alias)
        XCTAssertEqual(expression.raw, column)
        XCTAssertEqual(expression.raw, expression.description)
    }

    func testInitWithAlias() {
        // Act
        let expression = ColumnSQLExpression(name: column, alias: alias)

        // Assert
        XCTAssertEqual(expression.name, column)
        XCTAssertEqual(expression.alias, alias)
        XCTAssertEqual(expression.raw, "\(column) \(asKeyword) \(alias)")
        XCTAssertEqual(expression.raw, expression.description)
    }

    func testInitWithStringLiteral() {
        // Act
        let expression = ColumnSQLExpression(stringLiteral: column)

        // Assert
        XCTAssertEqual(expression.name, column)
        XCTAssertNil(expression.alias)
        XCTAssertEqual(expression.raw, column)
        XCTAssertEqual(expression.raw, expression.description)
    }

    func testInitWithStringLiteralHavingAlias() {
        // Arrange
        let stringLiteral = "\(column) \(asKeyword) \(alias)"

        // Act
        let expression = ColumnSQLExpression(stringLiteral: stringLiteral)

        // Assert
        XCTAssertEqual(expression.name, column)
        XCTAssertEqual(expression.alias, alias)
        XCTAssertEqual(expression.raw, stringLiteral)
        XCTAssertEqual(expression.raw, expression.description)
    }
}
