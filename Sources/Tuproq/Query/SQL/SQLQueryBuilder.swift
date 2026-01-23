public class SQLQueryBuilder: QueryBuilder {
    private var _expressions = [SQLExpression]()

    public init() {}

    public func addExpression(_ expression: SQLExpression) {
        _expressions.append(expression)
    }

    public func getExpressions() -> [SQLExpression] {
        _expressions
    }
}

public extension SQLQueryBuilder {
    func getQuery() -> SQLQuery {
        var raw = ""
        let expressions = getExpressions()

        for expression in expressions {
            if raw.isEmpty {
                raw = expression.raw
            } else {
                raw += " " + expression.raw
            }
        }

        return .init(raw)
    }
}

public extension SQLQueryBuilder {
    func create(
        table: String,
        ifNotExists: Bool = false,
        columns: Table.Column...,
        constraints: SQLConstraint...
    ) -> Self {
        create(
            table: table,
            ifNotExists: ifNotExists,
            columns: columns,
            constraints: constraints
        )
    }

    func create(
        table: String,
        ifNotExists: Bool = false,
        columns: [Table.Column] = .init(),
        constraints: [SQLConstraint] = .init()
    ) -> Self {
        addExpression(
            CreateTableSQLExpression(
                table: Table(
                    name: table,
                    columns: columns,
                    constraints: constraints
                ),
                ifNotExists: ifNotExists
            )
        )
        return self
    }
}

public extension SQLQueryBuilder {
    func insert(
        into table: String,
        columns: String...,
        values: Any?...
    ) -> Self {
        insert(
            into: table,
            columns: columns,
            values: values
        )
    }

    func insert(
        into table: String,
        columns: [String] = .init(),
        values: [Any?]
    ) -> Self {
        addExpression(
            InsertIntoSQLExpression(
                table: table,
                columns: columns,
                values: values
            )
        )
        return self
    }
}

public extension SQLQueryBuilder {
    func update(
        table: String,
        values: (String, Any?)...
    ) -> Self {
        update(
            table: table,
            values: values
        )
    }

    func update(
        table: String,
        values: [(String, Any?)]
    ) -> Self {
        addExpression(
            UpdateSQLExpression(
                table: table,
                values: values
            )
        )
        return self
    }
}

public extension SQLQueryBuilder {
    func delete() -> Self {
        addExpression(DeleteSQLExpression())
        return self
    }
}

public extension SQLQueryBuilder {
    func select(_ columns: String...) -> Self {
        select(columns)
    }

    func select(_ columns: [String]) -> Self {
        addExpression(SelectSQLExpression(columns: columns))
        return self
    }
}

public extension SQLQueryBuilder {
    func from(
        _ table: String,
        as alias: String?
    ) -> Self {
        addExpression(
            FromSQLExpression(
                tables: [
                    TableSQLExpression(
                        name: table,
                        alias: alias
                    )
                ]
            )
        )
        return self
    }

    func from(_ tables: String...) -> Self {
        from(tables)
    }

    func from(_ tables: [String]) -> Self {
        addExpression(FromSQLExpression(tables: tables))
        return self
    }
}

public extension SQLQueryBuilder {
    func `where`(_ condition: String) -> Self {
        addExpression(WhereSQLExpression(condition: condition))
        return self
    }

    func andWhere(_ condition: String) -> Self {
        addExpression(AndSQLExpression(condition: condition))
        return self
    }

    func orWhere(_ condition: String) -> Self {
        addExpression(OrSQLExpression(condition: condition))
        return self
    }
}

public extension SQLQueryBuilder {
    func having(_ condition: String) -> Self {
        addExpression(HavingSQLExpression(condition: condition))
        return self
    }

    func andHaving(_ condition: String) -> Self {
        addExpression(AndSQLExpression(condition: condition))
        return self
    }

    func orHaving(_ condition: String) -> Self {
        addExpression(OrSQLExpression(condition: condition))
        return self
    }
}

public extension SQLQueryBuilder {
    func join(
        _ table: String,
        as alias: String? = nil,
        on condition: String
    ) -> Self {
        addExpression(
            JoinSQLExpression(
                table: TableSQLExpression(
                    name: table,
                    alias: alias
                ),
                condition: condition
            )
        )
        return self
    }
}

public extension SQLQueryBuilder {
    func orderBy(_ columns: (String, SQLExpression.Ordering)...) -> Self {
        orderBy(columns)
    }

    func orderBy(_ columns: [(String, SQLExpression.Ordering)]) -> Self {
        addExpression(OrderBySQLExpression(columns: columns))
        return self
    }
}

public extension SQLQueryBuilder {
    func returning(_ columns: String...) -> Self {
        returning(columns)
    }

    func returning(_ columns: [String]) -> Self {
        addExpression(ReturningSQLExpression(columns: columns))
        return self
    }
}
