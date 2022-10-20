struct AnyMapping: Hashable {
    let field: AnyKeyPath
    let entity: AnyEntity.Type
    let isUnique: Bool?
    let isNullable: Bool?
    let column: String?
    let joinColumn: JoinTable.Column?
    let joinTable: JoinTable?
    let type: FieldType?
    let mappedBy: AnyKeyPath?
    let inversedBy: AnyKeyPath?

    init<E: Entity>(_ mapping: IDMapping<E>) {
        field = mapping.name
        entity = E.self
        isUnique = nil
        isNullable = nil
        type = mapping.type
        column = mapping.column
        joinColumn = nil
        joinTable = nil
        mappedBy = nil
        inversedBy = nil
    }

    init<E: Entity>(_ mapping: FieldMapping<E>) {
        field = mapping.name
        entity = E.self
        isUnique = mapping.column.isUnique
        isNullable = mapping.column.isNullable
        type = mapping.type
        column = mapping.column.name
        joinColumn = nil
        joinTable = nil
        mappedBy = nil
        inversedBy = nil
    }

    init<E: Entity>(_ mapping: ParentMapping<E>) {
        field = mapping.field
        entity = mapping.entity
        isUnique = nil
        isNullable = nil
        type = nil
        column = nil
        joinColumn = mapping.column
        joinTable = nil
        mappedBy = nil
        inversedBy = mapping.inversedBy
    }

    init<E: Entity>(_ mapping: ChildMapping<E>) {
        field = mapping.field
        entity = mapping.entity
        isUnique = nil
        isNullable = nil
        type = nil
        column = nil
        joinColumn = nil
        joinTable = nil
        mappedBy = mapping.mappedBy
        inversedBy = nil
    }

    init<E: Entity>(_ mapping: SiblingMapping<E>) {
        field = mapping.field
        entity = mapping.entity
        isUnique = nil
        isNullable = nil
        type = nil
        column = nil
        joinColumn = nil
        joinTable = mapping.joinTable
        mappedBy = mapping.mappedBy
        inversedBy = mapping.inversedBy
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.field == rhs.field
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(field)
    }
}
