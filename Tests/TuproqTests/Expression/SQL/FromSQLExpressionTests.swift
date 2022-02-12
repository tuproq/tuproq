@testable import Tuproq
import XCTest

final class FromSQLExpressionTests: XCTestCase {
    let table = TableSQLExpression(name: "table", alias: "t")

    func testInit() {
        // Act
        let expression = FromSQLExpression(tables: [table])

        // Assert
        XCTAssertEqual(expression.tables, [table])
        XCTAssertEqual(expression.raw, "\(SQLExpression.Kind.from) \(table)")
        XCTAssertEqual(expression.raw, expression.description)
    }
}
