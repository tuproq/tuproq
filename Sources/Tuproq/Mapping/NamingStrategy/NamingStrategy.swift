public protocol NamingStrategy {
    var referenceColumnName: String { get }

    func columnName(fieldName: String, entityName: String?) -> String
    func joinColumnName(fieldName: String) -> String
    func joinKeyColumnName(entityName: String, referenceColumnName: String?) -> String
    func joinTableName(sourceEntityName: String, targetEntityName: String, fieldName: String?) -> String
    func tableName(entityName: String) -> String
}

public extension NamingStrategy {
    func columnName<E: Entity>(fieldName: String, entity: E.Type?) -> String {
        if let entity = entity {
            return columnName(fieldName: fieldName, entityName: String(describing: entity))
        }

        return columnName(fieldName: fieldName, entityName: nil)
    }

    func joinKeyColumnName<E: Entity>(entity: E.Type, referenceColumnName: String? = nil) -> String {
        joinKeyColumnName(entityName: String(describing: entity), referenceColumnName: referenceColumnName)
    }

    func joinTableName<SE: Entity, TE: Entity>(
        sourceEntity: SE.Type,
        targetEntity: TE.Type,
        fieldName: String? = nil
    ) -> String {
        joinTableName(
            sourceEntityName: String(describing: sourceEntity),
            targetEntityName: String(describing: targetEntity),
            fieldName: fieldName
        )
    }

    func tableName<E: Entity>(entity: E.Type) -> String {
        tableName(entityName: String(describing: entity))
    }
}
