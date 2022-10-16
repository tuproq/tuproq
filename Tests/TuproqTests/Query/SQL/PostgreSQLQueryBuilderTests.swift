@testable import Tuproq
import XCTest

final class PostgreSQLQueryBuilderTests: XCTestCase {
    func testDelete() {
        // Arrange
        let queryBuilder = PostgreSQLQueryBuilder()

        // Act
        let query = queryBuilder
            .delete()
            .from("table", as: "t")
            .where("t.column1 = 1")
            .getQuery()

        // Assert
        XCTAssertEqual(query.raw, "DELETE FROM table AS t WHERE t.column1 = 1")
    }

    func testInsert() {
        // Arrange
        let queryBuilder = PostgreSQLQueryBuilder()

        // Act
        let query = queryBuilder
            .insert(
                into: "table",
                columns: ["column1", "column2", "column3"],
                values: [1, "value2", nil]
            )
            .getQuery()

        // Assert
        XCTAssertEqual(query.raw, "INSERT INTO table (column1, column2, column3) VALUES (1, 'value2', NULL)")
    }

    func testSelect() {
        // Arrange
        let queryBuilder = PostgreSQLQueryBuilder()

        // Act
        let query = queryBuilder
            .select("t1.column1", "t2.column1")
            .from("table1", as: "t1")
            .join("table2", as: "t2", on: "t1.column1 = t2.column1")
            .where("t1.column2 = 1")
            .andWhere("t2.column2 != 2")
            .having("SUM(t1.column3) > 10")
            .orHaving("AVG(t2.column3) < 20")
            .orderBy(("t1.column1", .asc), ("t2.column1", .desc))
            .getQuery()

        // Assert
        XCTAssertEqual(
            query.raw,
            """
            SELECT t1.column1, t2.column1 \
            FROM table1 AS t1 \
            JOIN table2 AS t2 ON t1.column1 = t2.column1 \
            WHERE t1.column2 = 1 AND t2.column2 != 2 \
            HAVING SUM(t1.column3) > 10 OR AVG(t2.column3) < 20 \
            ORDER BY t1.column1 ASC, t2.column1 DESC
            """
        )
    }

    func testUpdate() {
        // Arrange
        let queryBuilder = PostgreSQLQueryBuilder()

        // Act
        let query = queryBuilder
            .update(table: "table", values: [("column1", 1), ("column2", "value2"), ("column3", nil)])
            .where("column1 = 1")
            .getQuery()

        // Assert
        XCTAssertEqual(
            query.raw,
            "UPDATE table SET column1 = 1, column2 = 'value2', column3 = NULL WHERE column1 = 1"
        )
    }
}
