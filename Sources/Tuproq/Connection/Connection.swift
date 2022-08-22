import PostgreSQL

public final class Connection {
    public typealias Entity = AnyObject & Swift.Codable
    public static let defaultName = "default"
    public let name: String
    public let option: Option
    let connection: PostgreSQL.Connection

    public init(name: String = Connection.defaultName, option: Option) {
        self.name = name
        self.option = option
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
