@testable import Tuproq
import XCTest

final class ParentMappingTests: XCTestCase {
    func testInit() {
        final class Author: Entity {
            @Observed var id: Int?
        }

        // Arrange
        let field = "author"
        let entity: any Entity.Type = Author.self
        let inversedBy = "posts"
        let isUnique = true
        let isNullable = false
        let column = JoinTable.Column(name: "author_id", isUnique: isUnique, isNullable: isNullable)

        // Act
        var mapping = ParentMapping(entity: entity)

        // Assert
        XCTAssertEqual(mapping.field, field)
        XCTAssertTrue(mapping.entity == entity)
        XCTAssertNil(mapping.inversedBy)
        XCTAssertEqual(mapping.column, .init(stringLiteral: Configuration.namingStrategy.joinColumn(field: field)))

        // Act
        mapping = ParentMapping(field: field, entity: entity, inversedBy: inversedBy, column: column)

        // Assert
        XCTAssertEqual(mapping.field, field)
        XCTAssertTrue(mapping.entity == entity)
        XCTAssertEqual(mapping.inversedBy, inversedBy)
        XCTAssertEqual(mapping.column, column)
    }
}
