import Collections

public final class TuproqORM {
    public static var namingStrategy: NamingStrategy = SnakeCaseNamingStrategy()

    public let connection: Connection
    private var mappings = OrderedDictionary<String, AnyEntityMapping>()

    public init(connection: Connection) {
        self.connection = connection
    }
}

extension TuproqORM {
    public func addMapping<M: EntityMapping>(_ mapping: M) {
        mappings[String(describing: mapping.entity)] = AnyEntityMapping(mapping)
    }
}

extension TuproqORM {
    public func migrate() async throws {
        let allQueries = "BEGIN;\(createSchema())COMMIT;"

        if let result = try await connection.query(allQueries) {
            print(result)
        }
    }

    public func createSchema() -> String {
        var allQueries = ""

        for mapping in mappings.values {
            let tables = createTables(from: mapping)

            for table in tables {
                let queryBuilder = PostgreSQLQueryBuilder()
                let query = queryBuilder.create(
                    table: table.name,
                    columns: table.columns,
                    constraints: table.constraints
                ).getQuery()
                allQueries += "\(query);"
            }
        }

        return allQueries
    }

    private func createTable() -> [Table] {
        var tables = [Table]()

        for mapping in mappings.values {
            tables.append(contentsOf: createTables(from: mapping))
        }

        return tables
    }

    private func createTables<M: EntityMapping>(from mapping: M) -> [Table] {
        createTables(from: AnyEntityMapping(mapping))
    }

    private func createTables(from mapping: AnyEntityMapping) -> [Table] {
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
            let parentMapping = mappings[String(describing: parent.entity)]!
            let relationTable = parentMapping.table
            table.constraints.append(
                ForeignKeyConstraint(
                    column: parent.column.name,
                    relationTable: relationTable,
                    relationColumn: parent.column.referencedColumnName
                )
            )

            var columnConstraints = [Constraint]()

            if parent.column.isUnique {
                columnConstraints.append(UniqueConstraint(column: parent.column.name))
            }

            if !parent.column.isNullable {
                columnConstraints.append(NotNullConstraint())
            }

            for parentID in parentMapping.ids {
                let column = Table.Column(
                    name: parent.column.name,
                    type: parentID.type.name(for: connection.driver),
                    constraints: columnConstraints
                )
                table.columns.append(column)
            }
        }
    }

    private func siblings(mapping: AnyEntityMapping, tables: inout [Table]) {
        for sibling in mapping.siblings {
            if let siblingJoinTable = sibling.joinTable {
                let siblingMapping = mappings[String(describing: sibling.entity)]!
                let joinTableName = siblingJoinTable.name
                var joinTable: Table
                var joinTableIndex: Int?

                if let index = tables.firstIndex(where: { $0.name == joinTableName }) {
                    joinTableIndex = index
                    joinTable = tables[index]
                } else {
                    joinTable = Table(name: joinTableName)
                    ids(mapping: siblingMapping, table: &joinTable)
                }

                for column in siblingJoinTable.columns {
                    joinTable.columns.append(
                        Table.Column(
                            name: column.name,
                            type: "BIGSERIAL",
                            constraints: []
                        )
                    )
                    joinTable.constraints.append(
                        ForeignKeyConstraint(
                            column: column.name,
                            relationTable: mapping.table,
                            relationColumn: column.referencedColumnName
                        )
                    )
                }

                for column in siblingJoinTable.inverseColumns {
                    joinTable.columns.append(
                        Table.Column(
                            name: column.name,
                            type: "BIGSERIAL",
                            constraints: []
                        )
                    )
                    joinTable.constraints.append(
                        ForeignKeyConstraint(
                            column: column.name,
                            relationTable: siblingMapping.table,
                            relationColumn: column.referencedColumnName
                        )
                    )
                }

                if let index = joinTableIndex {
                    tables[index] = joinTable
                } else {
                    tables.append(joinTable)
                }
            }
        }
    }
}
