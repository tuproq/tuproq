public protocol NamingStrategy {
    var referenceColumn: String { get }

    func column(field: String, entity: String?) -> String
    func joinColumn(field: String) -> String
    func joinKeyColumn(entity: String, referenceColumn: String?) -> String
    func joinTable(sourceEntity: String, targetEntity: String, field: String?) -> String
    func table(entity: String) -> String
}

public extension NamingStrategy {
    func column<E: Entity>(field: String, entity: E.Type?) -> String {
        if let entity = entity {
            return column(field: field, entity: String(describing: entity))
        }

        return column(field: field, entity: nil)
    }

    func joinKeyColumn<E: Entity>(entity: E.Type, referenceColumn: String? = nil) -> String {
        joinKeyColumn(entity: String(describing: entity), referenceColumn: referenceColumn)
    }

    func joinTable<SE: Entity, TE: Entity>(
        sourceEntity: SE.Type,
        targetEntity: TE.Type,
        field: String? = nil
    ) -> String {
        joinTable(
            sourceEntity: String(describing: sourceEntity),
            targetEntity: String(describing: targetEntity),
            field: field
        )
    }

    func table<E: Entity>(entity: E.Type) -> String {
        table(entity: String(describing: entity))
    }
}
