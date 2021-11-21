import Foundation

extension Connection {
    public struct Option: Equatable {
        public static let defaultHost = "127.0.0.1"
        public var driver: Driver
        public var host: String
        public var port: Int
        public var username: String?
        public var password: String?
        public var database: String?

        public init(
            driver: Driver,
            host: String = Option.defaultHost,
            username: String? = nil,
            password: String? = nil,
            database: String? = nil
        ) {
            self.init(
                driver: driver,
                host: host,
                port: driver.port,
                username: username,
                password: password,
                database: database
            )
        }

        public init(
            driver: Driver,
            host: String = Option.defaultHost,
            port: Int,
            username: String? = nil,
            password: String? = nil,
            database: String? = nil
        ) {
            self.driver = driver
            self.host = host
            self.port = port
            self.username = username
            self.password = password
            self.database = database
        }

        public init?(url: URL) {
            guard let urlComponents = URLComponents(string: url.absoluteString),
                  let driverName = urlComponents.scheme,
                  let driver = Driver(rawValue: driverName) else { return nil }
            self.driver = driver
            host = urlComponents.host ?? Option.defaultHost
            port = urlComponents.port ?? driver.port
            username = urlComponents.user
            password = urlComponents.password
            let database = urlComponents.path.dropLeadingSlash()

            if !database.isEmpty {
                self.database = database
            }
        }
    }
}
