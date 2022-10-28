import Collections

public final class ORM {
    public static var namingStrategy: NamingStrategy = SnakeCaseNamingStrategy()

    public let connection: Connection
    private var mappings = OrderedDictionary<String, AnyEntityMapping>()
    private var joinColumnTypes = [String: String]()

    public init(connection: Connection) {
        self.connection = connection
    }
}

extension ORM {
    public func addMapping<M: EntityMapping>(_ mapping: M) {
        mappings[String(describing: mapping.entity)] = AnyEntityMapping(mapping)
    }

    public func createEntityManager<EM: EntityManager>() -> EM {
        EM(connection: connection)
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

        for mapping in mappings.values {
            let table = createTable(from: mapping)
            tables.append(table)
        }

        for mapping in mappings.values {
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
        createTable(from: AnyEntityMapping(mapping))
    }

    private func createTable(from mapping: AnyEntityMapping) -> Table {
        var table = Table(name: mapping.table)
        ids(mapping: mapping, table: &table)
        fields(mapping: mapping, table: &table)
        parents(mapping: mapping, table: &table)

        return table
    }

    private func createJoinTable(from mapping: AnyEntityMapping, tables: inout [Table]) {
        siblings(mapping: mapping, tables: &tables)
    }

    private func ids(mapping: AnyEntityMapping, table: inout Table) {
        let ids = Array(mapping.ids)

        if ids.count > 1 {
            table.constraints.append(PrimaryKeyConstraint(columns: ids.map { $0.column! }))
        } else {
            let id = ids[0]
            guard let columnName = id.column, let idType = id.type else { return }
            let column = Table.Column(
                name: columnName,
                type: idType.name(for: connection.driver),
                constraints: [
                    PrimaryKeyConstraint(column: columnName)
                ]
            )
            joinColumnTypes["\(table.name)_\(columnName)"] = column.type
            table.columns.append(column)
        }
    }

    private func fields(mapping: AnyEntityMapping, table: inout Table) {
        for field in mapping.fields {
            guard let isNullable = field.isNullable,
                  let isUnique = field.isUnique,
                  let fieldColumn = field.column,
                  let fieldType = field.type else { return }
            var columnConstraints = [Constraint]()

            if !isNullable {
                columnConstraints.append(NotNullConstraint())
            }

            if isUnique {
                columnConstraints.append(UniqueConstraint(column: fieldColumn))
            }

            let column = Table.Column(
                name: fieldColumn,
                type: fieldType.name(for: connection.driver),
                constraints: columnConstraints
            )
            table.columns.append(column)
        }
    }

    private func parents(mapping: AnyEntityMapping, table: inout Table) {
        for parent in mapping.parents {
            guard let parentColumn = parent.joinColumn else { return }
            let parentMapping = mappings[String(describing: parent.entity)]!
            let relationTable = parentMapping.table
            table.constraints.append(
                ForeignKeyConstraint(
                    column: parentColumn.name,
                    relationTable: relationTable,
                    relationColumn: parentColumn.referenceColumn
                )
            )

            var columnConstraints = [Constraint]()

            if parentColumn.isUnique {
                columnConstraints.append(UniqueConstraint(column: parentColumn.name))
            }

            if !parentColumn.isNullable {
                columnConstraints.append(NotNullConstraint())
            }

            for parentID in parentMapping.ids {
                if let parentIDType = parentID.type {
                    let column = Table.Column(
                        name: parentColumn.name,
                        type: parentIDType.name(for: connection.driver),
                        constraints: columnConstraints
                    )
                    table.columns.append(column)
                }
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
                            type: joinColumnTypes[column.name]!,
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
                            type: joinColumnTypes[column.name]!,
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
