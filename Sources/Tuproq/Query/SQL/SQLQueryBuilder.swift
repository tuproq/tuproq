public struct SQLQueryBuilder: QueryBuilder {
    private var _expressions = [SQLExpression]()

    public init() {}

    public mutating func addExpression(_ expression: SQLExpression) {
        _expressions.append(expression)
    }

    public func getExpressions() -> [SQLExpression] {
        _expressions
    }
}

public extension SQLQueryBuilder {
    func getQuery(bindings: [(String, Any?)]) -> SQLQuery {
        let raw = _expressions.map { $0.raw }.joined(separator: " ")
        return .init(
            raw,
            bindings: bindings
        )
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
        var copy = self
        copy.addExpression(
            CreateTableSQLExpression(
                table: Table(
                    name: table,
                    columns: columns,
                    constraints: constraints
                ),
                ifNotExists: ifNotExists
            )
        )

        return copy
    }
}

public extension SQLQueryBuilder {
    func insert(
        into table: String,
        columns: [String],
        values: [Any?]
    ) -> Self {
        var copy = self
        copy.addExpression(
            InsertIntoSQLExpression(
                table: table,
                columns: columns,
                values: values
            )
        )

        return copy
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
        var copy = self
        copy.addExpression(
            UpdateSQLExpression(
                table: table,
                values: values
            )
        )

        return copy
    }
}

public extension SQLQueryBuilder {
    func delete() -> Self {
        var copy = self
        copy.addExpression(DeleteSQLExpression())

        return copy
    }
}

public extension SQLQueryBuilder {
    func select(_ columns: String...) -> Self {
        select(columns)
    }

    func select(_ columns: [String]) -> Self {
        var copy = self
        copy.addExpression(SelectSQLExpression(columns: columns))

        return copy
    }
}

public extension SQLQueryBuilder {
    func from(
        _ table: String,
        as alias: String? = nil
    ) -> Self {
        var copy = self
        copy.addExpression(
            FromSQLExpression(
                tables: [TableSQLExpression(
                    name: table,
                    alias: alias
                )]
            )
        )

        return copy
    }

    func from(_ tables: [String]) -> Self {
        var copy = self
        copy.addExpression(FromSQLExpression(tables: tables))

        return copy
    }
}

public extension SQLQueryBuilder {
    func `where`(_ condition: String) -> Self {
        var copy = self
        copy.addExpression(WhereSQLExpression(condition: condition))

        return copy
    }

    func andWhere(_ condition: String) -> Self {
        var copy = self
        copy.addExpression(AndSQLExpression(condition: condition))

        return copy
    }

    func orWhere(_ condition: String) -> Self {
        var copy = self
        copy.addExpression(OrSQLExpression(condition: condition))

        return copy
    }
}

public extension SQLQueryBuilder {
    func having(_ condition: String) -> Self {
        var copy = self
        copy.addExpression(HavingSQLExpression(condition: condition))

        return copy
    }

    func andHaving(_ condition: String) -> Self {
        var copy = self
        copy.addExpression(AndSQLExpression(condition: condition))

        return copy
    }

    func orHaving(_ condition: String) -> Self {
        var copy = self
        copy.addExpression(OrSQLExpression(condition: condition))

        return copy
    }
}

public extension SQLQueryBuilder {
    func join(
        _ table: String,
        as alias: String? = nil,
        on condition: String
    ) -> Self {
        var copy = self
        copy.addExpression(
            JoinSQLExpression(
                table: TableSQLExpression(
                    name: table,
                    alias: alias
                ),
                condition: condition
            )
        )

        return copy
    }
}

public extension SQLQueryBuilder {
    func orderBy(_ columns: (String, SQLExpression.Ordering)...) -> Self {
        orderBy(columns)
    }

    func orderBy(_ columns: [(String, SQLExpression.Ordering)]) -> Self {
        var copy = self
        copy.addExpression(OrderBySQLExpression(columns: columns))

        return copy
    }
}

public extension SQLQueryBuilder {
    func returning(_ columns: String...) -> Self {
        returning(columns)
    }

    func returning(_ columns: [String]) -> Self {
        var copy = self
        copy.addExpression(ReturningSQLExpression(columns: columns))

        return copy
    }
}

