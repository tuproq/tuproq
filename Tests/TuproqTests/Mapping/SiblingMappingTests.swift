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
        let field = "users"
        let entity: any Entity.Type = User.self
        let mappedBy = "groups"

        // Act
        let mapping = SiblingMapping<Group>(field: field, entity: entity, mappedBy: mappedBy)

        // Assert
        XCTAssertEqual(mapping.field, field)
        XCTAssertTrue(mapping.entity == entity)
        XCTAssertEqual(mapping.mappedBy, mappedBy)
        XCTAssertNil(mapping.inversedBy)
        XCTAssertNil(mapping.joinTable)
    }

    func testInitWithInversedBy() {
        // Arrange
        let field = "groups"
        let entity: any Entity.Type = Group.self
        let inversedBy = "users"
        let joinTable = JoinTable(name: "user_group", columns: .init(), inverseColumns: .init())

        // Act
        let mapping = SiblingMapping<User>(field: field, entity: entity, inversedBy: inversedBy, joinTable: joinTable)

        // Assert
        XCTAssertEqual(mapping.field, field)
        XCTAssertTrue(mapping.entity == entity)
        XCTAssertNil(mapping.mappedBy)
        XCTAssertEqual(mapping.inversedBy, inversedBy)
        XCTAssertEqual(mapping.joinTable, joinTable)
    }
}
