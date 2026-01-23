public class SQLExpression: Expression, @unchecked Sendable {
    public let raw: String

    public init(raw: String) {
        self.raw = raw
    }
}

extension SQLExpression {
    enum Kind: String, CustomStringConvertible {
        case add = "ADD"
        case addConstraint = "ADD CONSTRAINT"
        case alter = "ALTER"
        case alterColumn = "ALTER COLUMN"
        case alterTable = "ALTER TABLE"
        case all = "ALL"
        case and = "AND"
        case any = "ANY"
        case `as` = "AS"
        case asc = "ASC"
        case backupDatabase = "BACKUP DATABASE"
        case between = "BETWEEN"
        case `case` = "CASE"
        case check = "CHECK"
        case column = "COLUMN"
        case constraint = "CONSTRAINT"
        case create = "CREATE"
        case createDatabase = "CREATE DATABASE"
        case createIndex = "CREATE INDEX"
        case createOrReplaceView = "CREATE OR REPLACE VIEW"
        case createTable = "CREATE TABLE"
        case createProcedure = "CREATE PROCEDURE"
        case createUniqueIndex = "CREATE UNIQUE INDEX"
        case createView = "CREATE VIEW"
        case database = "DATABASE"
        case `default` = "DEFAULT"
        case delete = "DELETE"
        case desc = "DESC"
        case distinct = "DISTINCT"
        case drop = "DROP"
        case dropColumn = "DROP COLUMN"
        case dropConstraint = "DROP CONSTRAINT"
        case dropDatabase = "DROP DATABASE"
        case dropDefault = "DROP DEFAULT"
        case dropIndex = "DROP INDEX"
        case dropTable = "DROP TABLE"
        case dropView = "DROP VIEW"
        case exec = "EXEC"
        case exists = "EXISTS"
        case foreignKey = "FOREIGN KEY"
        case from = "FROM"
        case fullOuterJoin = "FULL OUTER JOIN"
        case groupBy = "GROUP BY"
        case having = "HAVING"
        case `in` = "IN"
        case index = "INDEX"
        case innerJoin = "INNER JOIN"
        case insertInto = "INSERT INTO"
        case insertIntoSelect = "INSERT INTO SELECT"
        case isNull = "IS NULL"
        case isNotNull = "IS NOT NULL"
        case join = "JOIN"
        case leftJoin = "LEFT JOIN"
        case like = "LIKE"
        case limit = "LIMIT"
        case not = "NOT"
        case notNull = "NOT NULL"
        case null = "NULL"
        case on = "ON"
        case or = "OR"
        case orderBy = "ORDER BY"
        case outerJoin = "OUTER JOIN"
        case primaryKey = "PRIMARY KEY"
        case procedure = "PROCEDURE"
        case returning = "RETURNING"
        case rightJoin = "RIGHT JOIN"
        case rowNumber = "ROWNUM"
        case select = "SELECT"
        case selectDistinct = "SELECT DISTINCT"
        case selectInto = "SELECT INTO"
        case selectTop = "SELECT TOP"
        case set = "SET"
        case star = "*"
        case table = "TABLE"
        case top = "TOP"
        case truncateTable = "TRUNCATE TABLE"
        case union = "UNION"
        case unionAll = "UNION ALL"
        case unique = "UNIQUE"
        case update = "UPDATE"
        case values = "VALUES"
        case view = "VIEW"
        case `where` = "WHERE"

        var description: String { rawValue }
    }
}

extension SQLExpression {
    public enum Ordering: String, CustomStringConvertible, Sendable {
        case asc = "ASC"
        case desc = "DESC"

        public var description: String { rawValue }
    }
}
