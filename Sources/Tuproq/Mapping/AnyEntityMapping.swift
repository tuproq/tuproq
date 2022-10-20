struct AnyEntityMapping {
    let entity: AnyEntity.Type
    let table: String
    let ids: Set<AnyMapping>
    let fields: Set<AnyMapping>
    let parents: Set<AnyMapping>
    let children: Set<AnyMapping>
    let siblings: Set<AnyMapping>

    init<M: EntityMapping>(_ mapping: M) {
        entity = mapping.entity
        table = mapping.table
        ids = Set<AnyMapping>(mapping.ids.map { AnyMapping($0) })
        fields = Set<AnyMapping>(mapping.fields.map { AnyMapping($0) })
        parents = Set<AnyMapping>(mapping.parents.map { AnyMapping($0) })
        children = Set<AnyMapping>(mapping.children.map { AnyMapping($0) })
        siblings = Set<AnyMapping>(mapping.siblings.map { AnyMapping($0) })
    }
}
