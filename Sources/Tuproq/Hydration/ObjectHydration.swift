import Foundation

final class ObjectHydration {
    let entityManager: any EntityManager
    let result: Result
    let rootTable: String
    let tables: Set<String>
    let dateFormatter: DateFormatter

    private var hydratedObjects = [String: [String: [String: Any?]]]()
    private var tablesInHydration = Set<String>()
    private var tableIDColumnIndexes = [String: Int]()
    private var tableColumnIndexes = [String: [String: Int]]()
    private var tableColumnFieldMappings = [String: [String: FieldMapping]]()
    private var tableColumnParentMappings = [String: [String: ParentMapping]]()
    private var tableColumnChildMappings = [String: Set<ChildMapping>]()
    private var tableColumnSiblingMappings = [String: Set<SiblingMapping>]()

    init(
        entityManager: any EntityManager,
        result: Result,
        rootTable: String,
        tables: Set<String>,
        dateFormatter: DateFormatter = .iso8601
    ) {
        self.entityManager = entityManager
        self.result = result
        self.rootTable = rootTable
        self.tables = tables
        self.dateFormatter = dateFormatter
        gatherMetadata()
    }

    func hydrate() -> [[String: Any?]] {
        var array = [[String: Any?]]()

        if let entityMapping = entityManager.configuration.mapping(tableName: rootTable) {
            for row in result.rows {
                hydrateObject(from: row, into: &array, with: entityMapping)
            }
        }

        return array
    }

    private func hydrateAll(
        from row: [Codable?],
        into dictionary: inout [String: Any?],
        with entityMapping: any EntityMapping
    ) {
        let table = entityMapping.table.trimmingQuotes
        guard let tableColumns = tableColumnIndexes[table] else { return }

        for (column, index) in tableColumns {
            let value = row[index]

            if entityMapping.id.column == column {
                setValue(value, for: entityMapping.id.field, in: &dictionary)
            } else if let fieldMapping = tableColumnFieldMappings[table]?[column] {
                setValue(value, for: fieldMapping.field, in: &dictionary)
            } else if let parentMapping = tableColumnParentMappings[table]?[column] {
                if dictionary[parentMapping.field] == nil && value != nil {
                    if let parentEntityMapping = entityManager.configuration.mapping(from: parentMapping.entity) {
                        var parentDictionary = [String: Any?]()
                        hydrateAll(from: row, into: &parentDictionary, with: parentEntityMapping)
                        dictionary[parentMapping.field] = parentDictionary
                    }
                }
            }
        }

        if let childMappings = tableColumnChildMappings[table] {
            for childMapping in childMappings {
                hydrateArray(from: row, into: &dictionary, with: childMapping)
            }
        }

        if let siblingMappings = tableColumnSiblingMappings[table] {
            for siblingMapping in siblingMappings {
                hydrateArray(from: row, into: &dictionary, with: siblingMapping)
            }
        }
    }

    private func hydrateArray(
        from row: [Codable?],
        into dictionary: inout [String: Any?],
        with associationMapping: any AssociationMapping
    ) {
        if let entityMapping = entityManager.configuration.mapping(from: associationMapping.entity) {
            var array = dictionary[associationMapping.field] as? [[String: Any?]] ?? .init()
            hydrateObject(from: row, into: &array, with: entityMapping)
            dictionary[associationMapping.field] = array
        }
    }

    private func hydrateObject(
        from row: [Codable?],
        into array: inout [[String: Any?]],
        with entityMapping: any EntityMapping
    ) {
        let table = entityMapping.table.trimmingQuotes

        if let idIndex = tableIDColumnIndexes[table], let id = row[idIndex], !tablesInHydration.contains(table) {
            let id = String(describing: id)
            tablesInHydration.insert(table)

            if let dictionaryIndex = array.firstIndex(where: { $0[entityMapping.id.field] as? String == id }) {
                var dictionary = array[dictionaryIndex]
                hydrateAll(from: row, into: &dictionary, with: entityMapping)
                array[dictionaryIndex] = dictionary
            } else {
                var dictionary = [String: Any?]()
                hydrateAll(from: row, into: &dictionary, with: entityMapping)
                array.append(dictionary)
            }

            tablesInHydration.remove(table)
        }
    }

    private func setValue(_ value: Codable?, for field: String, in dictionary: inout [String: Any?]) {
        if let date = value as? Date {
            dictionary[field] = dateFormatter.string(from: date)
        } else if let uuid = value as? UUID {
            dictionary[field] = uuid.uuidString
        } else {
            dictionary[field] = value
        }
    }

    private func gatherMetadata() {
        for table in tables {
            if let entityMapping = entityManager.configuration.mapping(tableName: table) {
                var tables = tables
                tables.remove(table)

                let childMappings = entityMapping.children.filter {
                    tables.contains(entityManager.configuration.mapping(from: $0.entity)!.table.trimmingQuotes)
                }
                tableColumnChildMappings[table] = tableColumnChildMappings[table, default: .init()].union(childMappings)

                let siblingMappings = entityMapping.siblings.filter {
                    tables.contains(entityManager.configuration.mapping(from: $0.entity)!.table.trimmingQuotes)
                }
                tableColumnSiblingMappings[table] = tableColumnSiblingMappings[table, default: .init()].union(siblingMappings)
            }
        }

        for (index, column) in result.columns.enumerated() {
            if let idColumn = entityManager.configuration.mapping(tableName: column.table)?.id.column,
               idColumn == column.name {
                tableIDColumnIndexes[column.table] = index
            }

            tableColumnIndexes[column.table, default: .init()][column.name] = index

            if let entityMapping = entityManager.configuration.mapping(tableName: column.table) {
                if let fieldMapping = entityMapping.fields.first(where: { $0.column.name == column.name }) {
                    tableColumnFieldMappings[column.table, default: .init()][column.name] = fieldMapping
                } else if let parentMapping = entityMapping.parents.first(where: { $0.column.name == column.name }) {
                    tableColumnParentMappings[column.table, default: .init()][column.name] = parentMapping
                }
            }
        }
    }
}

extension ObjectHydration {
    struct Result {
        let columns: [Column]
        let rows: [[Codable?]]
    }

    struct Column: Hashable {
        let name: String
        let table: String
    }
}
