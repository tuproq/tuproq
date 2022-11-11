@testable import Tuproq
import XCTest

final class SiblingMappingTests: XCTestCase {
    func testInitWithMappedBy() {
        final class User: Entity {
            @Observed var id: Int?
        }

        // Arrange
        let field = "users"
        let entity: any Entity.Type = User.self
        let mappedBy = "groups"

        // Act
        let mapping = SiblingMapping(field: field, entity: entity, mappedBy: mappedBy)

        // Assert
        XCTAssertEqual(mapping.field, field)
        XCTAssertTrue(mapping.entity == entity)
        XCTAssertEqual(mapping.mappedBy, mappedBy)
        XCTAssertNil(mapping.inversedBy)
        XCTAssertNil(mapping.joinTable)
    }

    func testInitWithInversedBy() {
        final class Group: Entity {
            @Observed var id: Int?
        }

        // Arrange
        let field = "groups"
        let entity: any Entity.Type = Group.self
        let inversedBy = "users"
        let joinTable = JoinTable(name: "user_group", columns: .init(), inverseColumns: .init())

        // Act
        let mapping = SiblingMapping(field: field, entity: entity, inversedBy: inversedBy, joinTable: joinTable)

        // Assert
        XCTAssertEqual(mapping.field, field)
        XCTAssertTrue(mapping.entity == entity)
        XCTAssertNil(mapping.mappedBy)
        XCTAssertEqual(mapping.inversedBy, inversedBy)
        XCTAssertEqual(mapping.joinTable, joinTable)
    }
}
