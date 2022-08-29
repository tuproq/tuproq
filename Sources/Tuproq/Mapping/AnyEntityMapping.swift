struct AnyEntityMapping {
    typealias Entity = AnyObject & Codable

    let entity: Entity.Type
    let table: String
    let id: IDMapping
    let fields: Set<FieldMapping>
    let parents: Set<ParentMapping>

    init<M: EntityMapping>(_ mapping: M) {
        entity = mapping.entity
        table = mapping.table
        id = mapping.id
        fields = mapping.fields
        parents = mapping.parents
    }
}
