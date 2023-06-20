import Foundation

public final class Tuproq {
    public let connection: Connection
    public private(set) var configuration: Configuration

    public init(connection: Connection, configuration: Configuration = .init()) {
        self.connection = connection
        self.configuration = configuration
    }
}

extension Tuproq {
    public func addMapping<M: EntityMapping>(_ mapping: M) {
        configuration.addMapping(mapping)
    }

    public func mapping<E: Entity>(from entity: E) -> (any EntityMapping)? {
        configuration.mapping(from: entity)
    }

    public func mapping<E: Entity>(from entityType: E.Type) -> (any EntityMapping)? {
        configuration.mapping(from: entityType)
    }

    public func mapping(from entityType: any Entity.Type) -> (any EntityMapping)? {
        configuration.mapping(from: entityType)
    }

    public func mapping(entityName: String) -> (any EntityMapping)? {
        configuration.mapping(entityName: entityName)
    }

    public func mapping(tableName: String) -> (any EntityMapping)? {
        configuration.mapping(tableName: tableName)
    }

    public func createEntityManager() -> any EntityManager {
        switch connection.driver {
        case .mysql: return SQLEntityManager<MySQLQueryBuilder>(connection: connection, configuration: configuration)
        case .oracle: return SQLEntityManager<OracleQueryBuilder>(connection: connection, configuration: configuration)
        case .postgresql: return SQLEntityManager<PostgreSQLQueryBuilder>(connection: connection, configuration: configuration)
        case .sqlite: return SQLEntityManager<SQLiteQueryBuilder>(connection: connection, configuration: configuration)
        case .sqlserver: return SQLEntityManager<SQLServerQueryBuilder>(connection: connection, configuration: configuration)
        }
    }
}

extension Tuproq {
    public func migrate() async throws {
        let allQueries = "BEGIN;\(createSchema())COMMIT;"
        try await connection.query(allQueries)
    }

    public func beginTransaction() async throws {
        try await connection.beginTransaction()
    }

    public func commitTransaction() async throws {
        try await connection.commitTransaction()
    }

    public func rollbackTransaction() async throws {
        try await connection.rollbackTransaction()
    }

    public func createTables() -> [String] {
        var queries = [String]()
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
                ifNotExists: true,
                columns: table.columns,
                constraints: table.constraints
            ).getQuery()
            queries.append("\(query);")
        }

        return queries
    }

    public func createSchema() -> String {
        createTables().joined()
    }

    private func createTable<M: EntityMapping>(from mapping: M) -> Table {
        var table = Table(name: mapping.table)
        ids(mapping: mapping, table: &table)
        fields(mapping: mapping, table: &table)
        parents(mapping: mapping, table: &table)
        constraints(mapping: mapping, table: &table)

        return table
    }

    private func createJoinTable(from mapping: some EntityMapping, tables: inout [Table]) {
        siblings(mapping: mapping, tables: &tables)
    }

    private func ids(mapping: some EntityMapping, table: inout Table) {
        let id = mapping.id
        let columnName = id.column
        let idType = id.type
        let column = Table.Column(
            name: columnName,
            type: idType.name(for: connection.driver),
            constraints: [
                PrimaryKeySQLConstraint(column: columnName)
            ]
        )
        let tableName = table.name.trimmingCharacters(in: .init(charactersIn: "\""))
        configuration.joinColumnTypes["\(tableName)_\(columnName)"] = column.type
        table.columns.append(column)
    }

    private func fields(mapping: some EntityMapping, table: inout Table) {
        for field in mapping.fields {
            var columnConstraints = [SQLConstraint]()

            if !field.column.isNullable {
                columnConstraints.append(NotNullSQLConstraint())
            }

            if field.column.isUnique {
                columnConstraints.append(UniqueSQLConstraint(column: field.column.name))
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
                ForeignKeySQLConstraint(
                    column: parent.column.name,
                    relationTable: relationTable,
                    relationColumn: parent.column.referenceColumn
                )
            )

            var columnConstraints = [SQLConstraint]()

            if parent.column.isUnique {
                columnConstraints.append(UniqueSQLConstraint(column: parent.column.name))
            }

            if !parent.column.isNullable {
                columnConstraints.append(NotNullSQLConstraint())
            }

            let parentIDType = parentMapping.id.type
            let column = Table.Column(
                name: parent.column.name,
                type: parentIDType.name(for: connection.driver),
                constraints: columnConstraints
            )
            table.columns.append(column)
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
                    var columnConstraints = [SQLConstraint]()

                    if column.isUnique {
                        columnConstraints.append(UniqueSQLConstraint(column: column.name))
                    }

                    if !column.isNullable {
                        columnConstraints.append(NotNullSQLConstraint())
                    }

                    joinTable.columns.append(
                        Table.Column(
                            name: column.name,
                            type: configuration.joinColumnTypes[column.name]!,
                            constraints: columnConstraints
                        )
                    )
                    joinTable.constraints.append(
                        ForeignKeySQLConstraint(
                            column: column.name,
                            relationTable: mapping.table,
                            relationColumn: column.referenceColumn
                        )
                    )
                }

                for column in siblingJoinTable.inverseColumns {
                    var columnConstraints = [SQLConstraint]()

                    if column.isUnique {
                        columnConstraints.append(UniqueSQLConstraint(column: column.name))
                    }

                    if !column.isNullable {
                        columnConstraints.append(NotNullSQLConstraint())
                    }

                    joinTable.columns.append(
                        Table.Column(
                            name: column.name,
                            type: configuration.joinColumnTypes[column.name]!,
                            constraints: columnConstraints
                        )
                    )
                    joinTable.constraints.append(
                        ForeignKeySQLConstraint(
                            column: column.name,
                            relationTable: siblingMapping.table,
                            relationColumn: column.referenceColumn
                        )
                    )
                }

                for constraint in siblingJoinTable.constraints {
                    switch constraint {
                    case .unique(let columns, let index):
                        joinTable.constraints.append(UniqueSQLConstraint(columns: columns, index: index))
                    }
                }

                if let index = joinTableIndex {
                    tables[index] = joinTable
                } else {
                    tables.append(joinTable)
                }
            }
        }
    }

    private func constraints(mapping: some EntityMapping, table: inout Table) {
        for constraint in mapping.constraints {
            switch constraint {
            case .unique(let columns, let index):
                table.constraints.append(UniqueSQLConstraint(columns: columns, index: index))
            }
        }
    }
}
