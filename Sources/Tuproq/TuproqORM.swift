public final class TuproqORM {
    public let connection: Connection
    private var mappings = [AnyEntityMapping]()

    public init(connection: Connection) {
        self.connection = connection
    }
}

extension TuproqORM {
    public func addMapping<M: EntityMapping>(_ mapping: M) {
        mappings.append(AnyEntityMapping(mapping))
    }
}

extension TuproqORM {
    public func migrate() async throws {
        var allQueries = ""

        for mapping in mappings {
            let queryBuilder = PostgreSQLQueryBuilder()
            var constraints = [Constraint]()
            var columns = [Table.Column]()

            if mapping.id.columns.count > 1 {
                constraints.append(PrimaryKeyConstraint(columns: mapping.id.columns))
            } else {
                let columnName = mapping.id.columns[0]
                let column = Table.Column(
                    name: columnName,
                    type: mapping.id.type.name(for: connection.driver),
                    constraints: [
                        PrimaryKeyConstraint(column: columnName)
                    ]
                )
                columns.append(column)
            }

            for field in mapping.fields {
                var columnConstraints = [Constraint]()

                if !field.isNullable {
                    columnConstraints.append(NotNullConstraint())
                }

                if field.isUnique {
                    columnConstraints.append(UniqueConstraint(column: field.column))
                }

                let column = Table.Column(
                    name: field.column,
                    type: field.type.name(for: connection.driver),
                    constraints: columnConstraints
                )
                columns.append(column)
            }

            for parent in mapping.parents {
                constraints.append(
                    ForeignKeyConstraint(
                        column: parent.column,
                        relationTable: parent.parent.table,
                        relationColumn: "id"
                    )
                )

                var columnConstraints = [Constraint]()

                if !parent.isNullable {
                    columnConstraints.append(NotNullConstraint())
                }

                let column = Table.Column(
                    name: parent.column,
                    type: parent.parent.id.type.name(for: connection.driver),
                    constraints: columnConstraints
                )
                columns.append(column)
            }

            let query = queryBuilder.create(table: mapping.table, columns: columns, constraints: constraints).getQuery()
            allQueries += "\(query);"
        }

        allQueries = "BEGIN;\(allQueries)COMMIT;"

        if let result = try await connection.query(allQueries) {
            print(result)
        }
    }
}
