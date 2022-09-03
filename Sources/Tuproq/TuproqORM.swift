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
                    type: type(from: mapping.id.type),
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
                    type: type(from: field.type),
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
                    type: type(from: parent.parent.id.type),
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

    private func type(from type: FieldType) -> String {
        let driver = connection.driver

        switch type {
        case .bool:
            switch driver {
            case .mysql: return "TINYINT(1)"
            case .postgresql, .sqlite: return "BOOLEAN"
            case .oracle: return "NUMBER(1)"
            case .sqlserver: return "BIT"
            }
        case .character:
            switch driver {
            case .mysql, .postgresql: return "VARCHAR(1)"
            case .oracle: return "CHAR(1)"
            case .sqlite: return "TEXT"
            case .sqlserver: return "NCHAR(1)"
            }
        case .data(let length, let isFixed):
            if let length = length {
                switch driver {
                case .mysql:
                    if length <= 255 {
                        return isFixed ? "BINARY(\(length))" : "VARBINARY(\(length))" // options: TINYBLOB
                    } else if length <= 65535 {
                        return "BLOB"
                    } else if length <= 16777215 {
                        return "MEDIUMBLOB"
                    }

                    return "LONGBLOB"
                case .oracle, .sqlserver: return isFixed ? "BINARY(\(length))" : "VARBINARY(\(length))"
                case .postgresql: return "BYTEA"
                case .sqlite: return "BLOB"
                }
            } else {
                switch driver {
                case .mysql: return "LONGBLOB"
                case .postgresql: return "BYTEA"
                case .oracle, .sqlite: return "BLOB"
                case .sqlserver: return "VARBINARY(MAX)"
                }
            }
        case .date:
            switch driver {
            case .mysql, .sqlite, .sqlserver: return "DATETIME"
            case .postgresql, .oracle: return "TIMESTAMP(0) WITH TIME ZONE"
            }
        case .decimal(let precision, let scale, let isUnsigned):
            switch driver {
            case .mysql: return isUnsigned ? "UNSIGNED" : "NUMERIC(\(precision), \(scale))"
            case .postgresql, .oracle, .sqlite, .sqlserver: return "NUMERIC(\(precision), \(scale))"
            }
        case .double(let isUnsigned), .float(let isUnsigned):
            switch driver {
            case .mysql: return isUnsigned ? "UNSIGNED" : "DOUBLE PRECISION"
            case .postgresql, .oracle, .sqlite, .sqlserver: return "DOUBLE PRECISION"
            }
        case .id(let strategy):
            switch strategy {
            case .auto:
                switch driver {
                case .mysql: return "AUTO_INCREMENT"
                case .postgresql: return "BIGSERIAL"
                case .oracle, .sqlserver: return "IDENTITY"
                case .sqlite: return "INTEGER"
                }
            case .none(let type): return self.type(from: type)
            }
        case .int8, .int16, .uint8, .uint16:
            switch driver {
            case .mysql: return type == .int8 || type == .int16 ? "SMALLINT" : "UNSIGNED"
            case .postgresql: return "SMALLINT"
            case .oracle: return "NUMBERS(5)"
            case .sqlite: return "INTEGER"
            case .sqlserver: return "SMALLINT"
            }
        case .int32, .uint32:
            switch driver {
            case .mysql: return type == .int32 ? "INT" : "UNSIGNED"
            case .postgresql: return "INT"
            case .oracle: return "NUMBERS(10)"
            case .sqlite: return "INTEGER"
            case .sqlserver: return "INT"
            }
        case .int64, .uint64:
            switch driver {
            case .mysql: return type == .int64 ? "BIGINT" : "UNSIGNED"
            case .postgresql: return "BIGINT"
            case .oracle: return "NUMBERS(20)"
            case .sqlite: return "INTEGER"
            case .sqlserver: return "BIGINT"
            }
        case .string(let length, let isFixed):
            if let length = length {
                switch driver {
                case .mysql:
                    if length <= 255 {
                        return "VARCHAR(\(length))" // options: TINYTEXT
                    } else if length <= 65535 {
                        return "TEXT"
                    } else if length <= 16777215 {
                        return "MEDIUMTEXT"
                    }

                    return "LONGTEXT"
                case .oracle: return length <= 4000 ? (isFixed ? "CHAR(\(length))" : "VARCHAR2(\(length))") : "TEXT"
                case .postgresql: return length <= 65535 ? "VARCHAR(\(length))" : "TEXT"
                case .sqlite: return "TEXT"
                case .sqlserver: return length <= 4000 ? (isFixed ? "NCHAR(\(length))" : "NVARCHAR(\(length))") : "VARCHAR(MAX)"
                }
            } else {
                switch driver {
                case .mysql: return "LONGTEXT"
                case .oracle, .postgresql, .sqlite: return "TEXT"
                case .sqlserver: return "VARCHAR(MAX)"
                }
            }
        case .uuid:
            switch driver {
            case .mysql, .oracle, .sqlite: return "CHAR(36)"
            case .postgresql: return "UUID"
            case .sqlserver: return "UNIQUEIDENTIFIER"
            }
        }
    }
}
