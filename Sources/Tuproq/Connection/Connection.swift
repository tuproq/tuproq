public class Connection {
    public static let defaultName = "default"
    public let name: String
    public let option: Option
    public let entities: [Any.Type]

    public init(name: String = Connection.defaultName, option: Option, entities: [Any.Type] = .init()) {
        self.name = name
        self.option = option
        self.entities = entities
    }

    public func connect() async throws {
        // TODO: implement
    }

    public func disconnect() async throws {
        // TODO: implement
    }
}

extension Connection: Equatable {
    public static func == (lhs: Connection, rhs: Connection) -> Bool {
        lhs.name == rhs.name
    }
}
