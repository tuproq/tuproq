public struct SnakeCaseNamingStrategy: NamingStrategy {
    public var letterCase: String.LetterCase

    public var referenceColumnName: String {
        switch letterCase {
        case .lower: return "id"
        case .upper: return "ID"
        }
    }

    public init(letterCase: String.LetterCase = .lower) {
        self.letterCase = letterCase
    }

    public func columnName(fieldName: String, entityName: String?) -> String {
        fieldName.snakeCase(letterCase)
    }

    public func joinColumnName(fieldName: String) -> String {
        "\(fieldName.snakeCase(letterCase))_\(referenceColumnName)"
    }

    public func joinKeyColumnName(entityName: String, referenceColumnName: String?) -> String {
        "\(tableName(entityName: entityName))_\(referenceColumnName ?? self.referenceColumnName)"
    }

    public func joinTableName(sourceEntityName: String, targetEntityName: String, fieldName: String?) -> String {
        "\(tableName(entityName: sourceEntityName))_\(tableName(entityName: targetEntityName))"
    }

    public func tableName(entityName: String) -> String {
        let dot = "."
        var entityName = entityName

        if entityName.contains(dot) {
            entityName = entityName.components(separatedBy: dot).last ?? ""
        }

        return entityName.snakeCase(letterCase)
    }
}
