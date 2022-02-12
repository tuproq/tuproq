@testable import Tuproq
import XCTest

final class UpdateSQLExpressionTests: XCTestCase {
    func testInit() {
        // Arrange
        let table = "table"
        let values: [String: Any?] = ["column1": 1, "column2": "value2", "column3": nil]

        // Act
        let expression = UpdateSQLExpression(table: table, values: values)

        // Assert
        XCTAssertEqual(expression.table, table)
        XCTAssertEqual(expression.values.count, values.count)
        XCTAssertEqual(expression.values["column1"] as! Int, values["column1"] as! Int)
        XCTAssertEqual(expression.values["column2"] as! String, values["column2"] as! String)
        XCTAssertNil(expression.values["column3"]!)
        XCTAssertEqual(
            expression.raw,
            """
            \(SQLExpression.Kind.update) \(table) \
            \(SQLExpression.Kind.set) \(values.map({ "\($0.key) = \($0.value ?? "NULL")" }).joined(separator: ", "))
            """
        )
        XCTAssertEqual(expression.raw, expression.description)
    }
}
