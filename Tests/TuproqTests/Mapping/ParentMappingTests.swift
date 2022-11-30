@testable import Tuproq
import XCTest

private extension ParentMappingTests {
    final class Author: Entity {
        @Observed private(set) var id: Int?
        @Observed var posts: [Post]

        init(posts: [Post] = .init()) {
            self.posts = posts
        }
    }

    final class Post: Entity {
        @Observed private(set) var id: Int?
        @Observed var author: Author

        init(author: Author) {
            self.author = author
        }
    }
}

final class ParentMappingTests: XCTestCase {
    func testInit() {
        // Arrange
        let field = "author"
        let entity = Author.self
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
