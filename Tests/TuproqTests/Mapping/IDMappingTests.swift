@testable import Tuproq
import XCTest

final class IDMappingTests: XCTestCase {
    func testInit() {
        // Arrange
        let name = "id"
        let type: FieldType = .id()
        let column = "column_id"

        // Act
        var mapping = IDMapping()

        // Assert
        XCTAssertEqual(mapping.name, name)
        XCTAssertEqual(mapping.type, type)
        XCTAssertEqual(mapping.column, name)

        // Act
        mapping = IDMapping("", type: type)

        // Assert
        XCTAssertEqual(mapping.name, name)
        XCTAssertEqual(mapping.type, type)
        XCTAssertEqual(mapping.column, name)

        // Act
        mapping = IDMapping(name, type: type, column: column)

        // Assert
        XCTAssertEqual(mapping.name, name)
        XCTAssertEqual(mapping.type, type)
        XCTAssertEqual(mapping.column, column)
    }
}
