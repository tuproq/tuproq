@testable import Tuproq
import XCTest

final class InsertIntoSQLExpressionTests: XCTestCase {
    func testInit() {
        // Arrange
        let table = "table"
        let columns = ["column1", "column2", "column3"]
        let values: [Codable?] = [1, "value2", nil]

        // Act
        let expression = InsertIntoSQLExpression(
            table: table,
            columns: columns,
            values: values
        )

        // Assert
        XCTAssertEqual(expression.table, table)
        XCTAssertEqual(expression.columns, columns)
        XCTAssertEqual(expression.values.count, values.count)
        XCTAssertEqual(expression.values.first as! Int, values.first as! Int)
        XCTAssertEqual(expression.values[1] as! String, values[1] as! String)
        XCTAssertNil(expression.values.last!)
        XCTAssertEqual(
            expression.raw,
            """
            INSERT INTO table (column1, column2, column3) VALUES ({1}, {2}, {3})
            """
        )
        XCTAssertEqual(expression.raw, expression.description)
    }
}
