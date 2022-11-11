@testable import Tuproq
import XCTest

final class IDMappingTests: XCTestCase {
    func testInit() {
        // Arrange
        let field = "id"
        let type: FieldType = .id()
        let column = "column_id"

        // Act
        var mapping = IDMapping()

        // Assert
        XCTAssertEqual(mapping.field, field)
        XCTAssertEqual(mapping.type, type)
        XCTAssertEqual(mapping.column, field)

        // Act
        mapping = IDMapping(field: "", type: type)

        // Assert
        XCTAssertEqual(mapping.field, field)
        XCTAssertEqual(mapping.type, type)
        XCTAssertEqual(mapping.column, field)

        // Act
        mapping = IDMapping(field: field, type: type, column: column)

        // Assert
        XCTAssertEqual(mapping.field, field)
        XCTAssertEqual(mapping.type, type)
        XCTAssertEqual(mapping.column, column)
    }
}
