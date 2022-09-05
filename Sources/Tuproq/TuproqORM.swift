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
            var columns: [Table.Column] = [
                Table.Column(
                    name: mapping.id.column,
                    type: mapping.id.type.name(for: connection.driver),
                    constraints: [
                        PrimaryKeyConstraint(key: "pk_\(mapping.id.column)")
                    ]
                )
            ]

            for field in mapping.fields {
                var constraints = [Constraint]()

                if !field.isNullable {
                    constraints.append(NotNullConstraint())
                }

                if field.isUnique {
                    constraints.append(UniqueConstraint(column: field.column))
                }

                let column = Table.Column(
                    name: field.column,
                    type: field.type.name(for: connection.driver),
                    constraints: constraints
                )
                columns.append(column)
            }

            for parent in mapping.parents {
                var constraints = [Constraint]()
                constraints.append(ForeignKeyConstraint(key: parent.column))

                if !parent.isNullable {
                    constraints.append(NotNullConstraint())
                }

                let column = Table.Column(
                    name: parent.column,
                    type: parent.parent.id.type.name(for: connection.driver),
                    constraints: constraints
                )
                columns.append(column)
            }

            let query = queryBuilder.create(table: mapping.table, columns: columns).getQuery()
            allQueries += "\(query);"
        }

        allQueries = "BEGIN;\(allQueries)COMMIT;"

        if let result = try await connection.query(allQueries) {
            print(result)
        }
    }
}
