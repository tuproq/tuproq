@testable import Tuproq
import XCTest

final class DeleteSQLExpressionTests: XCTestCase {
    func testInit() {
        // Act
        let expression = DeleteSQLExpression()

        // Assert
        XCTAssertEqual(expression.raw, "\(SQLExpression.Kind.delete)")
        XCTAssertEqual(expression.raw, expression.description)
    }
}
