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
            let tables = createTables(from: mapping)

            for table in tables {
                let query = queryBuilder.create(
                    table: table.name,
                    columns: table.columns,
                    constraints: table.constraints
                ).getQuery()
                allQueries += "\(query);"
            }
        }

        allQueries = "BEGIN;\(allQueries)COMMIT;"

        if let result = try await connection.query(allQueries) {
            print(result)
        }
    }

    func createTable() -> [Table] {
        var tables = [Table]()

        for mapping in mappings {
            tables.append(contentsOf: createTables(from: mapping))
        }

        return tables
    }

    func createTables<M: EntityMapping>(from mapping: M) -> [Table] {
        createTables(from: AnyEntityMapping(mapping))
    }

    func createTables(from mapping: AnyEntityMapping) -> [Table] {
        var tables = [Table]()
        var table = Table(name: mapping.table)
        ids(mapping: mapping, table: &table)
        fields(mapping: mapping, table: &table)
        parents(mapping: mapping, table: &table)
        siblings(mapping: mapping, tables: &tables)
        tables.append(table)

        return tables
    }

    private func ids(mapping: AnyEntityMapping, table: inout Table) {
        let ids = Array(mapping.ids)

        if ids.count > 1 {
            table.constraints.append(PrimaryKeyConstraint(columns: ids.map { $0.column }))
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
            table.columns.append(column)
        }
    }

    private func fields(mapping: AnyEntityMapping, table: inout Table) {
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
            table.columns.append(column)
        }
    }

    private func parents(mapping: AnyEntityMapping, table: inout Table) {
        for parent in mapping.parents {
            table.constraints.append(
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
                table.columns.append(column)
            }
        }
    }

    private func siblings(mapping: AnyEntityMapping, tables: inout [Table]) {
        for sibling in mapping.siblings {
            let joinTableName = sibling.joinTable
            var joinTable: Table
            var joinTableIndex: Int?

            if let index = tables.firstIndex(where: { $0.name == joinTableName }) {
                joinTableIndex = index
                joinTable = tables[index]
            } else {
                joinTable = Table(name: joinTableName)
                ids(mapping: sibling.mapping, table: &joinTable)
            }

            joinTable.columns.append(
                Table.Column(
                    name: sibling.column,
                    type: "BIGSERIAL",
                    constraints: [
                        ForeignKeyConstraint(
                            column: sibling.column,
                            relationTable: sibling.mapping.table,
                            relationColumn: "id"
                        )
                    ]
                )
            )

            if let index = joinTableIndex {
                tables[index] = joinTable
            } else {
                tables.append(joinTable)
            }

            siblings(mapping: sibling.mapping, tables: &tables)
        }
    }
}
