@testable import Tuproq
import XCTest

final class JoinSQLExpressionTests: XCTestCase {
    func testInit() {
        // Arrange
        let table = TableSQLExpression(name: "table2", alias: "t2")
        let condition = "t1.id = t2.id"

        // Act
        let expression = JoinSQLExpression(table: table, condition: condition)

        // Assert
        XCTAssertEqual(expression.table, table)
        XCTAssertEqual(expression.raw, "\(SQLExpression.Kind.join) \(table) \(SQLExpression.Kind.on) \(condition)")
        XCTAssertEqual(expression.raw, expression.description)
    }
}
