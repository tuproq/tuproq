import Logging
import NIOCore

final actor ConnectionPools {
    let configuration: Configuration
    let logger: Logger
    let connectionFactory: ConnectionFactory

    private var pools = [ObjectIdentifier: ConnectionPool]()

    init(
        configuration: Configuration,
        logger: Logger,
        connectionFactory: @escaping ConnectionFactory
    ) {
        self.configuration = configuration
        self.logger = logger
        self.connectionFactory = connectionFactory
    }

    subscript(eventLoop: EventLoop) -> ConnectionPool {
        get async {
            let id = ObjectIdentifier(eventLoop)

            if let pool = pools[id] {
                return pool
            }

            let pool = ConnectionPool(
                eventLoop: eventLoop,
                logger: logger,
                size: configuration.poolSize,
                connectionFactory: connectionFactory
            )
            pool.activate()
            pools[id] = pool

            return pool
        }
    }
}
