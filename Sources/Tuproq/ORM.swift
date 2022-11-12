public final class ORM {
    public let connection: Connection
    public private(set) var configuration: Configuration

    public init(connection: Connection, configuration: Configuration = .init()) {
        self.connection = connection
        self.configuration = configuration
    }
}

extension ORM {
    public func addMapping<M: EntityMapping>(_ mapping: M) {
        configuration.addMapping(mapping)
    }

    public func createEntityManager<EM: EntityManager>() -> EM {
        EM(connection: connection, configuration: configuration)
    }
}

extension ORM {
    public func migrate() async throws {
        let allQueries = "BEGIN;\(createSchema())COMMIT;"

        if let result = try await connection.query(allQueries) {
            print(result)
        }
    }

    public func createSchema() -> String {
        var allQueries = ""
        var tables = [Table]()

        for mapping in configuration.mappings.values {
            let table = createTable(from: mapping)
            tables.append(table)
        }

        for mapping in configuration.mappings.values {
            createJoinTable(from: mapping, tables: &tables)
        }

        for table in tables {
            let queryBuilder = PostgreSQLQueryBuilder()
            let query = queryBuilder.create(
                table: table.name,
                columns: table.columns,
                constraints: table.constraints
            ).getQuery()
            allQueries += "\(query);"
        }

        return allQueries
    }

    private func createTable<M: EntityMapping>(from mapping: M) -> Table {
        createTable(from: mapping)
    }

    private func createTable(from mapping: any EntityMapping) -> Table {
        var table = Table(name: mapping.table)
        ids(mapping: mapping, table: &table)
        fields(mapping: mapping, table: &table)
        parents(mapping: mapping, table: &table)

        return table
    }

    private func createJoinTable(from mapping: any EntityMapping, tables: inout [Table]) {
        siblings(mapping: mapping, tables: &tables)
    }

    private func ids(mapping: any EntityMapping, table: inout Table) {
        let ids = Array(mapping.ids)

        if ids.count > 1 {
            table.constraints.append(PrimaryKeyConstraint(columns: ids.map { $0.column }))
        } else {
            let id = ids[0]
            let columnName = id.column
            let idType = id.type
            let column = Table.Column(
                name: columnName,
                type: idType.name(for: connection.driver),
                constraints: [
                    PrimaryKeyConstraint(column: columnName)
                ]
            )
            configuration.joinColumnTypes["\(table.name)_\(columnName)"] = column.type
            table.columns.append(column)
        }
    }

    private func fields(mapping: any EntityMapping, table: inout Table) {
        for field in mapping.fields {
            var columnConstraints = [Constraint]()

            if !field.column.isNullable {
                columnConstraints.append(NotNullConstraint())
            }

            if field.column.isUnique {
                columnConstraints.append(UniqueConstraint(column: field.column.name))
            }

            let column = Table.Column(
                name: field.column.name,
                type: field.type.name(for: connection.driver),
                constraints: columnConstraints
            )
            table.columns.append(column)
        }
    }

    private func parents(mapping: some EntityMapping, table: inout Table) {
        for parent in mapping.parents {
            let parentMapping = configuration.mapping(from: parent.entity)!
            let relationTable = parentMapping.table
            table.constraints.append(
                ForeignKeyConstraint(
                    column: parent.column.name,
                    relationTable: relationTable,
                    relationColumn: parent.column.referenceColumn
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
                let parentIDType = parentID.type
                let column = Table.Column(
                    name: parent.column.name,
                    type: parentIDType.name(for: connection.driver),
                    constraints: columnConstraints
                )
                table.columns.append(column)
            }
        }
    }

    private func siblings(mapping: some EntityMapping, tables: inout [Table]) {
        for sibling in mapping.siblings {
            if let siblingJoinTable = sibling.joinTable {
                let siblingMapping = configuration.mapping(from: sibling.entity)!
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
                    var columnConstraints = [Constraint]()

                    if column.isUnique {
                        columnConstraints.append(UniqueConstraint(column: column.name))
                    }

                    if !column.isNullable {
                        columnConstraints.append(NotNullConstraint())
                    }

                    joinTable.columns.append(
                        Table.Column(
                            name: column.name,
                            type: configuration.joinColumnTypes[column.name]!,
                            constraints: columnConstraints
                        )
                    )
                    joinTable.constraints.append(
                        ForeignKeyConstraint(
                            column: column.name,
                            relationTable: mapping.table,
                            relationColumn: column.referenceColumn
                        )
                    )
                }

                for column in siblingJoinTable.inverseColumns {
                    var columnConstraints = [Constraint]()

                    if column.isUnique {
                        columnConstraints.append(UniqueConstraint(column: column.name))
                    }

                    if !column.isNullable {
                        columnConstraints.append(NotNullConstraint())
                    }

                    joinTable.columns.append(
                        Table.Column(
                            name: column.name,
                            type: configuration.joinColumnTypes[column.name]!,
                            constraints: columnConstraints
                        )
                    )
                    joinTable.constraints.append(
                        ForeignKeyConstraint(
                            column: column.name,
                            relationTable: siblingMapping.table,
                            relationColumn: column.referenceColumn
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
