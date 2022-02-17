struct AnyRepository {
    let repository: Any

    init<R: Repository>(_ repository: R) {
        self.repository = repository
    }
}
