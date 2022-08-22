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
