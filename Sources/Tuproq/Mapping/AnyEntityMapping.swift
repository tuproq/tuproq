struct AnyEntityMapping {
    typealias Entity = AnyObject & Codable

    let entity: Entity.Type
    let table: String
    let ids: Set<IDMapping>
    let fields: Set<FieldMapping>
    let parents: Set<ParentMapping>
    let children: Set<ChildMapping>

    init<M: EntityMapping>(_ mapping: M) {
        entity = mapping.entity
        table = mapping.table
        ids = mapping.ids
        fields = mapping.fields
        parents = mapping.parents
        children = mapping.children
    }
}
