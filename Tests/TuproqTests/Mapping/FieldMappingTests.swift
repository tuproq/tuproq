@testable import Tuproq
import XCTest

final class FieldMappingTests: XCTestCase {
    func testInit() {
        // Arrange
        let field = "name"
        let type: FieldType = .string()
        let isUnique = true
        let isNullable = false
        let column = FieldMapping.Column(name: "column_name", isUnique: isUnique, isNullable: isNullable)

        // Act
        var mapping = FieldMapping(field: field, type: type)

        // Assert
        XCTAssertEqual(mapping.field, field)
        XCTAssertEqual(mapping.type, type)
        XCTAssertEqual(mapping.column, .init(stringLiteral: field))

        // Act
        mapping = FieldMapping(field: field, type: type, isUnique: isUnique, isNullable: isNullable)

        // Assert
        XCTAssertEqual(mapping.field, field)
        XCTAssertEqual(mapping.type, type)
        XCTAssertEqual(mapping.column, .init(name: field, isUnique: isUnique, isNullable: isNullable))

        // Act
        mapping = FieldMapping(field: field, type: type, column: column)

        // Assert
        XCTAssertEqual(mapping.field, field)
        XCTAssertEqual(mapping.type, type)
        XCTAssertEqual(mapping.column, column)
    }
}
