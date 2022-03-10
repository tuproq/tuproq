import PostgreSQL

public class Connection {
    public static let defaultName = "default"
    public let name: String
    public let option: Option
    public let entities: [Codable.Type]
    let connection: PostgreSQL.Connection

    public init(name: String = Connection.defaultName, option: Option, entities: [Codable.Type] = .init()) {
        self.name = name
        self.option = option
        self.entities = entities
        connection = PostgreSQL.Connection(
            .init(
                host: option.host,
                port: option.port,
                username: option.username,
                password: option.password,
                database: option.database,
                requiresTLS: false
            )
        )
    }

    public func connect() async throws {
        try await connection.connect()
    }

    public func close() async throws {
        try await connection.close()
    }
}

extension Connection: Equatable {
    public static func == (lhs: Connection, rhs: Connection) -> Bool {
        lhs.name == rhs.name
    }
}
