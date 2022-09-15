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
            let table = createTable(from: mapping)
            let query = queryBuilder.create(
                table: table.name,
                columns: table.columns,
                constraints: table.constraints
            ).getQuery()
            allQueries += "\(query);"
        }

        allQueries = "BEGIN;\(allQueries)COMMIT;"

        if let result = try await connection.query(allQueries) {
            print(result)
        }
    }

    func createTable<M: EntityMapping>(from mapping: M) -> Table {
        createTable(from: AnyEntityMapping(mapping))
    }

    func createTable(from mapping: AnyEntityMapping) -> Table {
        var columns = [Table.Column]()
        var constraints = [Constraint]()
        let ids = Array(mapping.ids)

        if ids.count > 1 {
            constraints.append(PrimaryKeyConstraint(columns: ids.map { $0.column }))
        } else {
            let id = ids[0]
            let columnName = id.column
            let column = Table.Column(
                name: columnName,
                type: id.type.name(for: connection.driver),
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
                ForeignKeyConstraint(column: parent.column, relationTable: parent.parent.table, relationColumn: "id")
            )

            var columnConstraints = [Constraint]()

            if parent.isUnique {
                columnConstraints.append(UniqueConstraint(column: parent.column))
            }

            if !parent.isNullable {
                columnConstraints.append(NotNullConstraint())
            }

            for parentID in parent.parent.ids {
                let column = Table.Column(
                    name: parent.column,
                    type: parentID.type.name(for: connection.driver),
                    constraints: columnConstraints
                )
                columns.append(column)
            }
        }

        return Table(name: mapping.table, columns: columns, constraints: constraints)
    }
}
