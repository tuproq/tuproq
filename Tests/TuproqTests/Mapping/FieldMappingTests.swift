@testable import Tuproq
import XCTest

final class FieldMappingTests: XCTestCase {
    func testInit() {
        // Arrange
        let name = "name"
        let type: FieldType = .string()
        let isUnique = true
        let isNullable = false
        let column = FieldMapping.Column("column_name", isUnique: isUnique, isNullable: isNullable)

        // Act
        var mapping = FieldMapping(name, type: type)

        // Assert
        XCTAssertEqual(mapping.name, name)
        XCTAssertEqual(mapping.type, type)
        XCTAssertEqual(mapping.column, .init(stringLiteral: name))

        // Act
        mapping = FieldMapping(name, type: type, isUnique: isUnique, isNullable: isNullable)

        // Assert
        XCTAssertEqual(mapping.name, name)
        XCTAssertEqual(mapping.type, type)
        XCTAssertEqual(mapping.column, .init(name, isUnique: isUnique, isNullable: isNullable))

        // Act
        mapping = FieldMapping(name, type: type, column: column)

        // Assert
        XCTAssertEqual(mapping.name, name)
        XCTAssertEqual(mapping.type, type)
        XCTAssertEqual(mapping.column, column)
    }
}
