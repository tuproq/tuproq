public struct SnakeCaseNamingStrategy: NamingStrategy {
    public var letterCase: String.LetterCase

    public var referenceColumn: String {
        switch letterCase {
        case .lower: return "id"
        case .upper: return "ID"
        }
    }

    public init(letterCase: String.LetterCase = .lower) {
        self.letterCase = letterCase
    }

    public func column(field: String, entity: String?) -> String {
        field.snakeCase(letterCase)
    }

    public func joinColumn(field: String) -> String {
        "\(field.snakeCase(letterCase))_\(referenceColumn)"
    }

    public func joinKeyColumn(entity: String, referenceColumn: String?) -> String {
        "\(table(entity: entity))_\(referenceColumn ?? self.referenceColumn)"
    }

    public func joinTable(sourceEntity: String, targetEntity: String, field: String?) -> String {
        "\(table(entity: sourceEntity))_\(table(entity: targetEntity))"
    }

    public func table(entity: String) -> String {
        let dot = "."
        var entity = entity

        if entity.contains(dot) {
            entity = entity.components(separatedBy: dot).last ?? ""
        }

        return entity.snakeCase(letterCase)
    }
}
