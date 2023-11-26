import Logging
import NIOCore

enum ConnectionPoolError: Error {
    case closed
    case timeout
}

public typealias ConnectionFactory = (EventLoop) async throws -> Connection

final class ConnectionPool {
    let eventLoop: EventLoop
    let logger: Logger
    let size: ClosedRange<Int>
    let backoffFactor: Float32
    let backoffDelay: TimeAmount
    let isLeaky: Bool
    let connectionFactory: ConnectionFactory

    private(set) var availableConnections: CircularBuffer<Connection>
    private(set) var leasedConnectionsCount: Int
    private(set) var pendingConnectionsCount: Int
    var activeConnectionsCount: Int {
        availableConnections.count + pendingConnectionsCount + leasedConnectionsCount
    }
    private var canAddConnection: Bool {
        isLeaky
        ? availableConnections.count < size.upperBound
        : availableConnections.count + leasedConnectionsCount < size.upperBound
    }
    private var queue: CircularBuffer<Request>
    private var state: State

    init(
        eventLoop: EventLoop,
        logger: Logger,
        size: ClosedRange<Int>,
        backoffFactor: Float32 = 2,
        backoffDelay: TimeAmount = .milliseconds(100),
        isLeaky: Bool = false,
        connectionFactory: @escaping ConnectionFactory
    ) {
        self.eventLoop = eventLoop
        self.logger = logger
        self.size = (size.lowerBound < 0 ? 0 : size.lowerBound)...(size.upperBound < 0 ? 0 : size.upperBound)
        self.backoffFactor = backoffFactor
        self.backoffDelay = backoffDelay
        self.isLeaky = isLeaky
        self.connectionFactory = connectionFactory

        availableConnections = .init(initialCapacity: self.size.upperBound)
        leasedConnectionsCount = 0
        pendingConnectionsCount = 0
        queue = CircularBuffer(initialCapacity: 8)
        state = .open
    }

    func activate() {
        eventLoop.inEventLoop
        ? createConnections()
        : eventLoop.execute { [weak self] in self?.createConnections() }
    }

    func leaseConnection(timeout: TimeAmount) async throws -> Connection {
        eventLoop.inEventLoop
        ? try await _leaseConnection(timeout).get()
        : try await eventLoop.flatSubmit { [unowned self] in self._leaseConnection(timeout) }.get()
    }

    func returnConnection(_ connection: Connection) {
        eventLoop.inEventLoop
        ? returnLeasedConnection(connection)
        : eventLoop.execute { [weak self] in self?.returnLeasedConnection(connection) }
    }

    func close() async throws {
        let promise = eventLoop.makePromise(of: Void.self)

        if eventLoop.inEventLoop {
            _close(promise: promise)
            return try await promise.futureResult.get()
        }

        return try await eventLoop.flatSubmit { [weak self] in
            self?._close(promise: promise)
            return promise.futureResult
        }.get()
    }
}

extension ConnectionPool {
    private func createConnections() {
        eventLoop.assertInEventLoop()
        guard case .open = state else { return }

        var requiredConnectionsCount = size.lowerBound - activeConnectionsCount
        logger.trace("Creating connections", metadata: ["count": "\(requiredConnectionsCount)"])

        while requiredConnectionsCount > 0 {
            createConnection(backoff: backoffDelay)
            requiredConnectionsCount -= 1
        }
    }

    private func createConnection(after delay: TimeAmount = .nanoseconds(0), backoff: TimeAmount) {
        eventLoop.assertInEventLoop()
        pendingConnectionsCount += 1

        eventLoop.scheduleTask(in: delay) { [weak self] in
            guard let self else { return }
            Task { [weak self] in
                guard let self else { return }

                do {
                    let connection = try await connectionFactory(eventLoop)
                    pendingConnectionsCount -= 1
                    connectionCreationSucceeded(connection)
                } catch {
                    pendingConnectionsCount -= 1
                    connectionCreationFailed(error, backoffDelay: backoff)
                }
            }
        }
    }

    private func connectionCreationSucceeded(_ connection: Connection) {
        eventLoop.assertInEventLoop()
        logger.trace("Connection succeeded", metadata: ["connection": "\(connection.id)"])

        switch state {
        case .open:
            connection.channel.closeFuture.whenComplete { [weak self] _ in self?.connectionClosed(connection) }
            _returnConnection(connection)
        case .closing: closeConnection(connection)
        case .closed:
            logger.critical("Connection created on closed pool", metadata: ["connection": "\(connection.id)"])
            preconditionFailure("Invalid state: \(state)")
        }
    }

    private func connectionCreationFailed(_ error: Error, backoffDelay: TimeAmount) {
        eventLoop.assertInEventLoop()
        logger.error("Connection failed", metadata: ["error": "\(error)"])

        switch state {
        case .open: break
        case .closing(let remaining, let promise):
            if remaining == 1 {
                state = .closed
                promise?.succeed()
            } else {
                state = .closing(remaining: remaining - 1, promise)
            }

            return
        case .closed: preconditionFailure("Invalid state: \(state)")
        }

        let shouldReconnect = size.lowerBound > activeConnectionsCount || 
        (isLeaky ? queue.count > pendingConnectionsCount : !queue.isEmpty && size.upperBound > activeConnectionsCount)

        guard shouldReconnect else {
            logger.debug("Reconnection failed")
            return
        }

        let backoff = TimeAmount.nanoseconds(.init(Float32(backoffDelay.nanoseconds) * backoffFactor))
        logger.debug("Reconnecting", metadata: ["backoffDelay": "\(backoffDelay)ns", "backoff": "\(backoff)ns"])
        createConnection(after: backoffDelay, backoff: backoff)
    }

    private func connectionClosed(_ connection: Connection) {
        if let index = availableConnections.firstIndex(where: { $0 === connection }) {
            availableConnections.remove(at: index)
        }

        createConnections()
    }

    private func leaseConnection(_ connection: Connection, to request: Request) {
        eventLoop.assertInEventLoop()
        leasedConnectionsCount += 1
        request.succeed(connection)
    }

    private func _leaseConnection(_ timeout: TimeAmount) -> EventLoopFuture<Connection> {
        eventLoop.assertInEventLoop()

        guard case .open = state else {
            logger.trace("Attempted to lease connection from closed pool")
            return eventLoop.makeFailedFuture(ConnectionPoolError.closed)
        }

        var request = Request(response: eventLoop.makePromise())

        while let connection = availableConnections.popLast() {
            if connection.isOpen {
                logger.trace("Found available connection", metadata: ["connection": "\(connection.id)"])
                leaseConnection(connection, to: request)

                return request.response.futureResult
            }
        }

        request.scheduleDeadline(.now() + timeout, on: eventLoop) { [weak self] in
            self?.logger.trace("Connection not found in time")
            request.fail(ConnectionPoolError.timeout)
            guard let index = self?.queue.firstIndex(where: { $0.id == request.id }) else { return }
            self?.queue.remove(at: index)
        }
        queue.append(request)

        if isLeaky || activeConnectionsCount < size.upperBound {
            logger.trace("Creating new connection")
            createConnection(backoff: backoffDelay)
        }

        return request.response.futureResult
    }

    private func returnLeasedConnection(_ connection: Connection) {
        eventLoop.assertInEventLoop()
        leasedConnectionsCount -= 1

        switch state {
        case .open: _returnConnection(connection)
        case .closing: closeConnection(connection)
        case .closed: preconditionFailure("Invalid state: \(state)")
        }
    }

    private func _returnConnection(_ connection: Connection) {
        eventLoop.assertInEventLoop()
        precondition(state.isOpen)

        guard connection.isOpen else {
            createConnections()
            return
        }

        if let request = queue.popFirst() {
            leaseConnection(connection, to: request)
        } else if canAddConnection {
            availableConnections.append(connection)
        } else if let evictedConnection = availableConnections.popFirst() {
            availableConnections.append(connection)
            Task { try await evictedConnection.close() }
        } else {
            Task { try await connection.close() }
        }
    }

    private func closeConnection(_ connection: Connection) {
        Task {
            try await connection.close()

            switch state {
            case .closing(let remaining, let promise):
                if remaining == 1 {
                    state = .closed
                    promise?.succeed()
                } else {
                    state = .closing(remaining: remaining - 1, promise)
                }
            default: preconditionFailure("Invalid state: \(state)")
            }
        }
    }

    private func _close(promise: EventLoopPromise<Void>?) {
        switch state {
        case .open: 
            state = .closing(remaining: activeConnectionsCount, promise)

            while let request = queue.popFirst() {
                request.fail(ConnectionPoolError.closed)
            }

            if activeConnectionsCount != 0 {
                let connections = availableConnections
                availableConnections.removeAll()

                for connection in connections {
                    closeConnection(connection)
                }
            } else {
                logger.trace("Pool closed")
                state = .closed
                promise?.succeed()
            }
        case .closing(let count, let existingPromise):
            if let existingPromise = existingPromise {
                existingPromise.futureResult.cascade(to: promise)
            } else {
                state = .closing(remaining: count, promise)
            }
        case .closed: promise?.succeed()
        }
    }
}

extension ConnectionPool {
    enum State {
        case open
        case closing(remaining: Int, EventLoopPromise<Void>?)
        case closed

        var isOpen: Bool {
            switch self {
            case .open: return true
            default: return false
            }
        }
    }
}

extension ConnectionPool {
    struct Request {
        var id: ObjectIdentifier { .init(response.futureResult) }
        let response: EventLoopPromise<Connection>
        private var timeoutTask: Scheduled<Void>?

        init(response: EventLoopPromise<Connection>) {
            self.response = response
        }

        mutating func scheduleDeadline(
            _ deadline: NIODeadline,
            on eventLoop: EventLoop,
            _ task: @escaping () -> Void
        ) {
            timeoutTask?.cancel()
            timeoutTask = eventLoop.scheduleTask(deadline: deadline, task)
        }

        func succeed(_ connection: Connection) {
            timeoutTask?.cancel()
            response.succeed(connection)
        }

        func fail(_ error: Error) {
            timeoutTask?.cancel()
            response.fail(error)
        }
    }
}
