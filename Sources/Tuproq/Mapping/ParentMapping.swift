public struct ParentMapping: AssociationMapping {
    public let field: String
    public let entity: any Entity.Type
    public let inversedBy: String?
    public let column: JoinTable.Column
    public let constraints: Set<Constraint>

    public enum Constraint: Hashable {
        case delete(_ action: Action)

        public enum Action: Hashable {
            case cascade
        }
    }

    public init<Target: Entity>(
        entity: Target.Type,
        inversedBy: String? = nil,
        isUnique: Bool = false,
        isNullable: Bool = true,
        on constraints: Set<Constraint> = [.delete(.cascade)]
    ) {
        self.init(
            field: "",
            entity: entity,
            inversedBy: inversedBy,
            column: .init(name: "", isUnique: isUnique, isNullable: isNullable),
            on: constraints
        )
    }

    public init<Target: Entity>(
        field: String,
        entity: Target.Type,
        inversedBy: String? = nil,
        isUnique: Bool = false,
        isNullable: Bool = true,
        on constraints: Set<Constraint> = [.delete(.cascade)]
    ) {
        self.init(
            field: field,
            entity: entity,
            inversedBy: inversedBy,
            column: .init(name: "", isUnique: isUnique, isNullable: isNullable),
            on: constraints
        )
    }

    public init<Target: Entity>(
        entity: Target.Type,
        inversedBy: String? = nil,
        column: JoinTable.Column,
        on constraints: Set<Constraint> = [.delete(.cascade)]
    ) {
        self.init(
            field: "",
            entity: entity,
            inversedBy: inversedBy,
            column: column,
            on: constraints
        )
    }

    public init<Target: Entity>(
        field: String,
        entity: Target.Type,
        inversedBy: String? = nil,
        column: JoinTable.Column,
        on constraints: Set<Constraint> = [.delete(.cascade)]
    ) {
        if field.isEmpty {
            self.field = String(describingNestedType: entity).components(separatedBy: ".").last!.camelCased
        } else {
            self.field = field
        }

        self.entity = entity
        self.inversedBy = inversedBy
        self.constraints = constraints

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
