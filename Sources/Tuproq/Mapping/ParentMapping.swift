public struct ParentMapping: AssociationMapping {
    public let field: String
    public let entity: any Entity.Type
    public let inversedBy: String?
    public let column: JoinTable.Column

    public init<Target: Entity>(
        entity: Target.Type,
        inversedBy: String? = nil,
        isUnique: Bool = false,
        isNullable: Bool = true
    ) {
        self.init(
            field: "",
            entity: entity,
            inversedBy: inversedBy,
            column: .init(name: "", isUnique: isUnique, isNullable: isNullable)
        )
    }

    public init<Target: Entity>(
        field: String,
        entity: Target.Type,
        inversedBy: String? = nil,
        isUnique: Bool = false,
        isNullable: Bool = true
    ) {
        self.init(
            field: field,
            entity: entity,
            inversedBy: inversedBy,
            column: .init(name: "", isUnique: isUnique, isNullable: isNullable)
        )
    }

    public init<Target: Entity>(
        entity: Target.Type,
        inversedBy: String? = nil,
        column: JoinTable.Column
    ) {
        self.init(
            field: "",
            entity: entity,
            inversedBy: inversedBy,
            column: column
        )
    }

    public init<Target: Entity>(
        field: String,
        entity: Target.Type,
        inversedBy: String? = nil,
        column: JoinTable.Column
    ) {
        if field.isEmpty {
            self.field = String(describingNestedType: entity).components(separatedBy: ".").last!.camelCased
        } else {
            self.field = field
        }

        self.entity = entity
        self.inversedBy = inversedBy

        if column.name.isEmpty {
            self.column = .init(
                name: Configuration.namingStrategy.joinColumn(field: self.field),
                referenceColumn: column.referenceColumn,
                isUnique: column.isUnique,
                isNullable: column.isNullable
            )
        } else {
            self.column = column
        }
    }
}
