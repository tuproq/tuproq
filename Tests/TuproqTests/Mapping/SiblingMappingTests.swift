@testable import Tuproq
import XCTest

private extension SiblingMappingTests {
    final class User: Entity {
        @Observed private(set) var id: Int?
        @Observed var groups: [Group]

        init(groups: [Group] = .init()) {
            self.groups = groups
        }
    }

    final class Group: Entity {
        @Observed private(set) var id: Int?
        @Observed var users: [User]

        init(users: [User] = .init()) {
            self.users = users
        }
    }
}

final class SiblingMappingTests: XCTestCase {
    func testInitWithMappedBy() {
        // Arrange
        let name = "users"
        let entity = User.self
        let mappedBy = "groups"

        // Act
        let mapping = SiblingMapping(name, entity: entity, mappedBy: mappedBy)

        // Assert
        XCTAssertEqual(mapping.name, name)
        XCTAssertTrue(mapping.entity == entity)
        XCTAssertEqual(mapping.mappedBy, mappedBy)
        XCTAssertNil(mapping.inversedBy)
        XCTAssertNil(mapping.joinTable)
    }

    func testInitWithInversedBy() {
        // Arrange
        let name = "groups"
        let entity = Group.self
        let inversedBy = "users"
        let joinTable = JoinTable(name: "user_group", columns: ["user_id"], inverseColumns: ["group_id"])

        // Act
        let mapping = SiblingMapping(name, entity: entity, inversedBy: inversedBy, joinTable: joinTable)

        // Assert
        XCTAssertEqual(mapping.name, name)
        XCTAssertTrue(mapping.entity == entity)
        XCTAssertNil(mapping.mappedBy)
        XCTAssertEqual(mapping.inversedBy, inversedBy)
        XCTAssertEqual(mapping.joinTable, joinTable)
    }
}
