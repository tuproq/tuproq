public protocol NamingStrategy {
    var referenceColumn: String { get }

    func column(field: String, entity: String?) -> String
    func joinColumn(field: String) -> String
    func joinKeyColumn(entity: String, referenceColumn: String?) -> String
    func joinTable(sourceEntity: String, targetEntity: String, field: String?) -> String
    func table(entity: String) -> String
}

public extension NamingStrategy {
    func column(field: String) -> String {
        column(field: field, entity: nil)
    }

    func column<E: Entity>(field: String, entity: E.Type?) -> String {
        if let entity = entity {
            return column(field: field, entity: Configuration.entityName(from: entity))
        }

        return column(field: field, entity: nil)
    }

    func joinKeyColumn<E: Entity>(entity: E.Type, referenceColumn: String? = nil) -> String {
        joinKeyColumn(entity:Configuration.entityName(from: entity), referenceColumn: referenceColumn)
    }

    func joinTable<SE: Entity, TE: Entity>(
        sourceEntity: SE.Type,
        targetEntity: TE.Type,
        field: String? = nil
    ) -> String {
        joinTable(
            sourceEntity: Configuration.entityName(from: sourceEntity),
            targetEntity: Configuration.entityName(from: targetEntity),
            field: field
        )
    }

    func joinColumn<E: Entity>(entity: E.Type) -> String {
        let field = Configuration.entityName(from: entity).components(separatedBy: ".").last!
        return joinColumn(field: field)
    }

    func table<E: Entity>(entity: E.Type) -> String {
        table(entity: Configuration.entityName(from: entity))
    }
}
