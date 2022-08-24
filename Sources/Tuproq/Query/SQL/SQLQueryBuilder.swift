public class SQLQueryBuilder: QueryBuilder {
    private var expressions = [SQLExpression]()

    public init() {}

    public func getQuery() -> SQLQuery {
        var raw = ""

        for expression in expressions {
            if raw.isEmpty {
                raw = expression.raw
            } else {
                raw += " " + expression.raw
            }
        }

        raw = raw.replacingOccurrences(of: "\"", with: "'")

        return .init(raw)
    }
}

extension SQLQueryBuilder {
    func create(table: String, columns: Table.Column...) -> Self {
        create(table: table, columns: columns)
    }

    func create(table: String, columns: [Table.Column] = .init()) -> Self {
        expressions.append(CreateTableSQLExpression(table: Table(name: table, columns: columns)))
        return self
    }
}

extension SQLQueryBuilder {
    public func insert(into table: String, columns: String..., values: Any?...) -> Self {
        insert(into: table, columns: columns, values: values)
    }

    public func insert(into table: String, columns: [String] = .init(), values: [Any?]) -> Self {
        expressions.append(InsertIntoSQLExpression(table: table, columns: columns, values: values))
        return self
    }
}

extension SQLQueryBuilder {
    public func update(_ table: String, set values: (String, Any?)...) -> Self {
        update(table, set: values)
    }

    public func update(_ table: String, set values: [(String, Any?)]) -> Self {
        expressions.append(UpdateSQLExpression(table: table, values: values))
        return self
    }
}

extension SQLQueryBuilder {
    public func delete() -> Self {
        expressions.append(DeleteSQLExpression())
        return self
    }
}

extension SQLQueryBuilder {
    public func select(_ columns: String...) -> Self {
        select(columns)
    }

    public func select(_ columns: [String]) -> Self {
        expressions.append(SelectSQLExpression(columns: columns))
        return self
    }
}

extension SQLQueryBuilder {
    public func from(_ table: String, as alias: String?) -> Self {
        expressions.append(FromSQLExpression(tables: [TableSQLExpression(name: table, alias: alias)]))
        return self
    }

    public func from(_ tables: String...) -> Self {
        from(tables)
    }

    public func from(_ tables: [String]) -> Self {
        expressions.append(FromSQLExpression(tables: tables))
        return self
    }
}

extension SQLQueryBuilder {
    public func `where`(_ condition: String) -> Self {
        expressions.append(WhereSQLExpression(condition: condition))
        return self
    }

    public func andWhere(_ condition: String) -> Self {
        expressions.append(AndSQLExpression(condition: condition))
        return self
    }

    public func orWhere(_ condition: String) -> Self {
        expressions.append(OrSQLExpression(condition: condition))
        return self
    }
}

extension SQLQueryBuilder {
    public func having(_ condition: String) -> Self {
        expressions.append(HavingSQLExpression(condition: condition))
        return self
    }

    public func andHaving(_ condition: String) -> Self {
        expressions.append(AndSQLExpression(condition: condition))
        return self
    }

    public func orHaving(_ condition: String) -> Self {
        expressions.append(OrSQLExpression(condition: condition))
        return self
    }
}

extension SQLQueryBuilder {
    public func join(_ table: String, as alias: String? = nil, on condition: String) -> Self {
        expressions.append(
            JoinSQLExpression(table: TableSQLExpression(name: table, alias: alias), condition: condition)
        )
        return self
    }
}

extension SQLQueryBuilder {
    public func orderBy(_ columns: (String, SQLExpression.Sorting)...) -> Self {
        orderBy(columns)
    }

    public func orderBy(_ columns: [(String, SQLExpression.Sorting)]) -> Self {
        expressions.append(OrderBySQLExpression(columns: columns))
        return self
    }
}

extension SQLQueryBuilder {
    public func returning(_ columns: String...) -> Self {
        returning(columns)
    }

    public func returning(_ columns: [String]) -> Self {
        expressions.append(ReturningSQLExpression(columns: columns))
        return self
    }
}
