struct AnyEntityMapping {
    typealias Entity = AnyObject & Codable

    let entity: Entity.Type
    let table: String
    let id: IDMapping
    let fields: Set<FieldMapping>

    init<M: EntityMapping>(_ mapping: M) {
        self.entity = mapping.entity
        self.table = mapping.table
        self.id = mapping.id
        self.fields = mapping.fields
    }
}
