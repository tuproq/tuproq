struct AnyEntity {
    let entity: Any

    init<E: Entity>(_ entity: E) {
        self.entity = entity
    }
}
