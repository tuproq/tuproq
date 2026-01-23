public struct ParentMapping: AssociationMapping {
    public let name: String
    public let entity: any Entity.Type
    public let inversedBy: String?
    public let column: JoinTable.Column
    public let constraints: Set<Constraint>

    public enum Constraint: Hashable, Sendable {
        case delete(_ action: Action)

        public enum Action: Hashable, Sendable {
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
            "",
            entity: entity,
            inversedBy: inversedBy,
            column: .init(
                "",
                isUnique: isUnique,
                isNullable: isNullable
            ),
            on: constraints
        )
    }

    public init<Target: Entity>(
        _ name: String,
        entity: Target.Type,
        inversedBy: String? = nil,
        isUnique: Bool = false,
        isNullable: Bool = true,
        on constraints: Set<Constraint> = [.delete(.cascade)]
    ) {
        self.init(
            name,
            entity: entity,
            inversedBy: inversedBy,
            column: .init(
                "",
                isUnique: isUnique,
                isNullable: isNullable
            ),
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
            "",
            entity: entity,
            inversedBy: inversedBy,
            column: column,
            on: constraints
        )
    }

    public init<Target: Entity>(
        _ name: String,
        entity: Target.Type,
        inversedBy: String? = nil,
        column: JoinTable.Column,
        on constraints: Set<Constraint> = [.delete(.cascade)]
    ) {
        self.entity = entity
        self.inversedBy = inversedBy
        self.constraints = constraints

        if name.isEmpty {
            self.name = String(describingNestedType: entity)
                .components(separatedBy: ".")
                .last?
                .camelCased ?? ""
        } else {
            self.name = name
        }

        if column.name.isEmpty {
            self.column = .init(
                Configuration.namingStrategy.joinColumn(field: self.name),
                referenceColumn: column.referenceColumn,
                isUnique: column.isUnique,
                isNullable: column.isNullable
            )
        } else {
            self.column = column
        }
    }
}
