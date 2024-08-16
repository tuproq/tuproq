public indirect enum FieldType: Hashable {
    case bool
    case character
    case data(length: UInt? = nil, isFixed: Bool = false)
    case date
    case decimal(precision: UInt, scale: UInt, isUnsigned: Bool = false)
    case double(isUnsigned: Bool = false)
    case float(isUnsigned: Bool = false)
    case id(_ strategy: IDGeneratorStrategy = .auto)
    case int8
    case int16
    case int32
    case int64
    case string(length: UInt? = nil, isFixed: Bool = false)
    case uint8
    case uint16
    case uint32
    case uint64
    case url
    case uuid

    public func name(for driver: DatabaseDriver) -> String {
        switch self {
        case .bool:
            switch driver {
            case .mysql: "TINYINT(1)"
            case .postgresql, .sqlite: "BOOLEAN"
            case .oracle: "NUMBER(1)"
            case .sqlserver: "BIT"
            }
        case .character:
            switch driver {
            case .mysql, .postgresql: "VARCHAR(1)"
            case .oracle: "CHAR(1)"
            case .sqlite: "TEXT"
            case .sqlserver: "NCHAR(1)"
            }
        case .data(let length, let isFixed):
            if let length = length {
                switch driver {
                case .mysql:
                    if length <= 255 {
                        isFixed ? "BINARY(\(length))" : "VARBINARY(\(length))" // options: TINYBLOB
                    } else if length <= 65535 {
                        "BLOB"
                    } else if length <= 16777215 {
                        "MEDIUMBLOB"
                    } else {
                        "LONGBLOB"
                    }
                case .oracle, .sqlserver: isFixed ? "BINARY(\(length))" : "VARBINARY(\(length))"
                case .postgresql: "BYTEA"
                case .sqlite: "BLOB"
                }
            } else {
                switch driver {
                case .mysql: "LONGBLOB"
                case .postgresql: "BYTEA"
                case .oracle, .sqlite: "BLOB"
                case .sqlserver: "VARBINARY(MAX)"
                }
            }
        case .date:
            switch driver {
            case .mysql, .sqlite, .sqlserver: "DATETIME"
            case .postgresql, .oracle: "TIMESTAMP(0) WITH TIME ZONE"
            }
        case .decimal(let precision, let scale, let isUnsigned):
            switch driver {
            case .mysql: isUnsigned ? "UNSIGNED" : "NUMERIC(\(precision), \(scale))"
            case .postgresql, .oracle, .sqlite, .sqlserver: "NUMERIC(\(precision), \(scale))"
            }
        case .double(let isUnsigned), .float(let isUnsigned):
            switch driver {
            case .mysql: isUnsigned ? "UNSIGNED" : "DOUBLE PRECISION"
            case .postgresql, .oracle, .sqlite, .sqlserver: "DOUBLE PRECISION"
            }
        case .id(let strategy):
            switch strategy {
            case .auto:
                switch driver {
                case .mysql: "AUTO_INCREMENT"
                case .postgresql: "BIGSERIAL"
                case .oracle, .sqlserver: "IDENTITY"
                case .sqlite: "INTEGER"
                }
            case .custom(let type): type.name(for: driver)
            }
        case .int8, .int16, .uint8, .uint16:
            switch driver {
            case .mysql: self == .int8 || self == .int16 ? "SMALLINT" : "UNSIGNED"
            case .postgresql: "SMALLINT"
            case .oracle: "NUMBERS(5)"
            case .sqlite: "INTEGER"
            case .sqlserver: "SMALLINT"
            }
        case .int32, .uint32:
            switch driver {
            case .mysql: self == .int32 ? "INT" : "UNSIGNED"
            case .postgresql: "INT"
            case .oracle: "NUMBERS(10)"
            case .sqlite: "INTEGER"
            case .sqlserver: "INT"
            }
        case .int64, .uint64:
            switch driver {
            case .mysql: self == .int64 ? "BIGINT" : "UNSIGNED"
            case .postgresql: "BIGINT"
            case .oracle: "NUMBERS(20)"
            case .sqlite: "INTEGER"
            case .sqlserver: "BIGINT"
            }
        case .string(let length, let isFixed):
            if let length = length {
                switch driver {
                case .mysql:
                    if length <= 255 {
                        "VARCHAR(\(length))" // options: TINYTEXT
                    } else if length <= 65535 {
                        "TEXT"
                    } else if length <= 16777215 {
                        "MEDIUMTEXT"
                    } else {
                        "LONGTEXT"
                    }
                case .oracle: length <= 4000 ? (isFixed ? "CHAR(\(length))" : "VARCHAR2(\(length))") : "TEXT"
                case .postgresql: length <= 65535 ? "VARCHAR(\(length))" : "TEXT"
                case .sqlite: "TEXT"
                case .sqlserver: length <= 4000 ? (isFixed ? "NCHAR(\(length))" : "NVARCHAR(\(length))") : "VARCHAR(MAX)"
                }
            } else {
                switch driver {
                case .mysql: "LONGTEXT"
                case .oracle, .postgresql, .sqlite: "TEXT"
                case .sqlserver: "VARCHAR(MAX)"
                }
            }
        case .url:
            switch driver {
            case .mysql: "LONGTEXT"
            case .oracle, .postgresql, .sqlite: "TEXT"
            case .sqlserver: "VARCHAR(MAX)"
            }
        case .uuid:
            switch driver {
            case .mysql, .oracle, .sqlite: "CHAR(36)"
            case .postgresql: "UUID"
            case .sqlserver: "UNIQUEIDENTIFIER"
            }
        }
    }
}
