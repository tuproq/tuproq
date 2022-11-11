@testable import Tuproq
import XCTest

final class ChildMappingTests: XCTestCase {
    func testInit() {
        final class Post: Entity {
            @Observed var id: Int?
        }

        // Arrange
        let field = "posts"
        let entity: any Entity.Type = Author.self
        let mappedBy = "author"

        // Act
        var mapping = ChildMapping(field: field, entity: entity)

        // Assert
        XCTAssertEqual(mapping.field, field)
        XCTAssertTrue(mapping.entity == entity)
        XCTAssertNil(mapping.mappedBy)

        // Act
        mapping = ChildMapping(field: field, entity: entity, mappedBy: mappedBy)

        // Assert
        XCTAssertEqual(mapping.field, field)
        XCTAssertTrue(mapping.entity == entity)
        XCTAssertEqual(mapping.mappedBy, mappedBy)
    }
}
