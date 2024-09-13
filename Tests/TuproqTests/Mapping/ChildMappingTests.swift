@testable import Tuproq
import XCTest

private extension ChildMappingTests {
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

final class ChildMappingTests: XCTestCase {
    func testInit() {
        // Arrange
        let name = "posts"
        let entity = Post.self
        let mappedBy = "author"
        let isUnique = true

        // Act
        var mapping = ChildMapping(name, entity: entity, mappedBy: mappedBy)

        // Assert
        XCTAssertEqual(mapping.name, name)
        XCTAssertTrue(mapping.entity == entity)
        XCTAssertEqual(mapping.mappedBy, mappedBy)
        XCTAssertFalse(mapping.isUnique)

        // Act
        mapping = ChildMapping(name, entity: entity, mappedBy: mappedBy, isUnique: isUnique)

        // Assert
        XCTAssertEqual(mapping.name, name)
        XCTAssertTrue(mapping.entity == entity)
        XCTAssertEqual(mapping.mappedBy, mappedBy)
        XCTAssertEqual(mapping.isUnique, isUnique)
    }
}
