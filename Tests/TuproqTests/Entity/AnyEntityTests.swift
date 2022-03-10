@testable import Tuproq
import XCTest

final class AnyEntityTests: XCTestCase {
    func testInit() {
        // Arrange
        let concreteEntity = ConcreteEntity(id: 1)

        // Act
        let anyEntity = AnyEntity(concreteEntity)

        // Assert
        XCTAssertEqual(anyEntity.entity as! ConcreteEntity, concreteEntity)
        XCTAssertEqual(anyEntity.name, String(describing: ConcreteEntity.self))
    }
}

extension AnyEntityTests {
    private final class ConcreteEntity: Entity {
        var id: Int

        init(id: Int) {
            self.id = id
        }
    }
}
