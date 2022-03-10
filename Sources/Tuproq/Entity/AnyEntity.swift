struct AnyEntity {
    var entity: Codable
    let name: String

    init<E: Entity>(_ entity: E) {
        self.entity = entity
        name = E.entity
    }
}
