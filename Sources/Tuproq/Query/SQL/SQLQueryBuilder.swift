public protocol SQLQueryBuilder: QueryBuilder {
    var expressions: [SQLExpression] { set get }

    init()
}

public extension SQLQueryBuilder {
    func getQuery() -> SQLQuery {
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

public extension SQLQueryBuilder {
    func create(table: String, columns: Table.Column..., constraints: SQLConstraint...) -> Self {
        create(table: table, columns: columns, constraints: constraints)
    }

    func create(table: String, columns: [Table.Column] = .init(), constraints: [SQLConstraint] = .init()) -> Self {
        expressions.append(
            CreateTableSQLExpression(table: Table(name: table, columns: columns, constraints: constraints))
        )
        return self
    }
}

public extension SQLQueryBuilder {
    func insert(into table: String, columns: String..., values: Any?...) -> Self {
        insert(into: table, columns: columns, values: values)
    }

    func insert(into table: String, columns: [String] = .init(), values: [Any?]) -> Self {
        expressions.append(InsertIntoSQLExpression(table: table, columns: columns, values: values))
        return self
    }
}

public extension SQLQueryBuilder {
    func update(table: String, values: (String, Codable?)...) -> Self {
        update(table: table, values: values)
    }

    func update(table: String, values: [(String, Codable?)]) -> Self {
        expressions.append(UpdateSQLExpression(table: table, values: values))
        return self
    }
}

public extension SQLQueryBuilder {
    func delete() -> Self {
        expressions.append(DeleteSQLExpression())
        return self
    }
}

public extension SQLQueryBuilder {
    func select(_ columns: String...) -> Self {
        select(columns)
    }

    func select(_ columns: [String]) -> Self {
        expressions.append(SelectSQLExpression(columns: columns))
        return self
    }
}

public extension SQLQueryBuilder {
    func from(_ table: String, as alias: String?) -> Self {
        expressions.append(FromSQLExpression(tables: [TableSQLExpression(name: table, alias: alias)]))
        return self
    }

    func from(_ tables: String...) -> Self {
        from(tables)
    }

    func from(_ tables: [String]) -> Self {
        expressions.append(FromSQLExpression(tables: tables))
        return self
    }
}

public extension SQLQueryBuilder {
    func `where`(_ condition: String) -> Self {
        expressions.append(WhereSQLExpression(condition: condition))
        return self
    }

    func andWhere(_ condition: String) -> Self {
        expressions.append(AndSQLExpression(condition: condition))
        return self
    }

    func orWhere(_ condition: String) -> Self {
        expressions.append(OrSQLExpression(condition: condition))
        return self
    }
}

public extension SQLQueryBuilder {
    func having(_ condition: String) -> Self {
        expressions.append(HavingSQLExpression(condition: condition))
        return self
    }

    func andHaving(_ condition: String) -> Self {
        expressions.append(AndSQLExpression(condition: condition))
        return self
    }

    func orHaving(_ condition: String) -> Self {
        expressions.append(OrSQLExpression(condition: condition))
        return self
    }
}

public extension SQLQueryBuilder {
    func join(_ table: String, as alias: String? = nil, on condition: String) -> Self {
        expressions.append(
            JoinSQLExpression(table: TableSQLExpression(name: table, alias: alias), condition: condition)
        )
        return self
    }
}

public extension SQLQueryBuilder {
    func orderBy(_ columns: (String, SQLExpression.Sorting)...) -> Self {
        orderBy(columns)
    }

    func orderBy(_ columns: [(String, SQLExpression.Sorting)]) -> Self {
        expressions.append(OrderBySQLExpression(columns: columns))
        return self
    }
}

public extension SQLQueryBuilder {
    func returning(_ columns: String...) -> Self {
        returning(columns)
    }

    func returning(_ columns: [String]) -> Self {
        expressions.append(ReturningSQLExpression(columns: columns))
        return self
    }
}
