struct AnyMapping: Hashable {
    let column: String?
    let entity: AnyEntity.Type
    let field: AnyKeyPath
    let inversedBy: AnyKeyPath?
    let isNullable: Bool?
    let isUnique: Bool?
    let joinColumn: JoinTable.Column?
    let joinTable: JoinTable?
    let mappedBy: AnyKeyPath?
    let type: FieldType?

    init<E: Entity>(_ mapping: IDMapping<E>) {
        column = mapping.column
        entity = E.self
        field = mapping.name
        inversedBy = nil
        isNullable = nil
        isUnique = nil
        joinColumn = nil
        joinTable = nil
        mappedBy = nil
        type = mapping.type
    }

    init<E: Entity>(_ mapping: FieldMapping<E>) {
        column = mapping.column.name
        entity = E.self
        field = mapping.name
        inversedBy = nil
        isNullable = mapping.column.isNullable
        isUnique = mapping.column.isUnique
        joinColumn = nil
        joinTable = nil
        mappedBy = nil
        type = mapping.type
    }

    init<E: Entity>(_ mapping: ParentMapping<E>) {
        column = nil
        entity = mapping.entity
        field = mapping.field
        inversedBy = mapping.inversedBy
        isNullable = nil
        isUnique = nil
        joinColumn = mapping.column
        joinTable = nil
        mappedBy = nil
        type = nil
    }

    init<E: Entity>(_ mapping: ChildMapping<E>) {
        column = nil
        entity = mapping.entity
        field = mapping.field
        inversedBy = nil
        isNullable = nil
        isUnique = nil
        joinColumn = nil
        joinTable = nil
        mappedBy = mapping.mappedBy
        type = nil
    }

    init<E: Entity>(_ mapping: SiblingMapping<E>) {
        column = nil
        entity = mapping.entity
        field = mapping.field
        inversedBy = mapping.inversedBy
        isNullable = nil
        isUnique = nil
        joinColumn = nil
        joinTable = mapping.joinTable
        mappedBy = mapping.mappedBy
        type = nil
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.field == rhs.field
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(field)
    }
}
