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
        let name = "author"
        let entity = Author.self
        let inversedBy = "posts"
        let isUnique = true
        let isNullable = false
        let column = JoinTable.Column(
            "author_id",
            isUnique: isUnique,
            isNullable: isNullable
        )

        // Act
        var mapping = ParentMapping(entity: entity)

        // Assert
        XCTAssertEqual(
            mapping.name,
            String(describingNestedType: entity).components(separatedBy: ".").last?.camelCased ?? ""
        )
        XCTAssertTrue(mapping.entity == entity)
        XCTAssertNil(mapping.inversedBy)
        XCTAssertEqual(
            mapping.column,
            .init(
                Configuration.namingStrategy.joinColumn(field: mapping.name),
                referenceColumn: mapping.column.referenceColumn
            )
        )
        XCTAssertEqual(mapping.constraints, [.delete(.cascade)])

        // Act
        mapping = ParentMapping(
            name,
            entity: entity,
            inversedBy: inversedBy,
            column: column
        )

        // Assert
        XCTAssertEqual(mapping.name, name)
        XCTAssertTrue(mapping.entity == entity)
        XCTAssertEqual(mapping.inversedBy, inversedBy)
        XCTAssertEqual(mapping.column, column)
        XCTAssertEqual(mapping.constraints, [.delete(.cascade)])
    }
}
