struct AnyEntity {
    let entity: Codable

    init<E: Entity>(_ entity: E) {
        self.entity = entity
    }
}
