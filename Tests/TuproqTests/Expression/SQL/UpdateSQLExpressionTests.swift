@testable import Tuproq
import XCTest

final class UpdateSQLExpressionTests: XCTestCase {
    func testInit() {
        // Arrange
        let table = "table"
        let values: [(String, Codable?)] = [("column1", 1), ("column2", "value2"), ("column3", nil)]

        // Act
        let expression = UpdateSQLExpression(table: table, values: values)

        // Assert
        XCTAssertEqual(expression.table, table)
        XCTAssertEqual(expression.values.count, values.count)
        XCTAssertEqual(expression.values[0].0, values[0].0)
        XCTAssertEqual(expression.values[0].1 as! Int, values[0].1 as! Int)
        XCTAssertEqual(expression.values[1].0, values[1].0)
        XCTAssertEqual(expression.values[1].1 as! String, values[1].1 as! String)
        XCTAssertEqual(expression.values[2].0, values[2].0)
        XCTAssertNil(expression.values[2].1)
        XCTAssertEqual(
            expression.raw,
            """
            \(SQLExpression.Kind.update) \(table) \
            \(SQLExpression.Kind.set) column1 = {1}, column2 = {2}, column3 = {3}
            """
        )
        XCTAssertEqual(expression.raw, expression.description)
    }
}
