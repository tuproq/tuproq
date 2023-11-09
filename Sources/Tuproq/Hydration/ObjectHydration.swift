import Foundation

extension String {
    var trimmingQuotes: String {
        trimmingCharacters(in: .init(charactersIn: "\""))
    }
}

final class ObjectHydration {
    let entityManager: any EntityManager
    let result: Result
    let rootTable: String
    let tables: Set<String>
    let dateFormatter: DateFormatter

    private var tablesInHydration = Set<String>()
    private var tableIDColumnIndexes = [String: Int]()
    private var tableColumnIndexes = [String: [String: Int]]()
    private var tableColumnFieldMappings = [String: [String: FieldMapping]]()
    private var tableColumnParentMappings = [String: [String: ParentMapping]]()
    private var tableColumnChildMappings = [String: Set<ChildMapping>]()
    private var tableColumnSiblingMappings = [String: Set<SiblingMapping>]()

    init(entityManager: any EntityManager, result: Result, rootTable: String, tables: Set<String>, dateFormatter: DateFormatter = .iso8601) {
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
                hydrateObject(for: row, with: entityMapping, in: &array)
            }
        }

        return array
    }

    private func hydrateAll(
        for row: [Codable?],
        with entityMapping: any EntityMapping,
        in dictionary: inout [String: Any?]
    ) {
        let table = entityMapping.table.trimmingQuotes

        if let tableColumns = tableColumnIndexes[table] {
            for (column, index) in tableColumns {
                let value = row[index]

                if entityMapping.id.column == column {
                    updateValue(value, for: entityMapping.id.field, in: &dictionary)
                } else if let fieldMapping = tableColumnFieldMappings[table]?[column] {
                    updateValue(value, for: fieldMapping.field, in: &dictionary)
                } else if let parentMapping = tableColumnParentMappings[table]?[column] {
                    if dictionary[parentMapping.field] == nil && value != nil {
                        if let parentEntityMapping = entityManager.configuration.mapping(from: parentMapping.entity) {
                            var parentDictionary = [String: Any?]()
                            hydrateAll(for: row, with: parentEntityMapping, in: &parentDictionary)
                            dictionary[parentMapping.field] = parentDictionary
                        }
                    }
                }
            }

            if let childMappings = tableColumnChildMappings[table] {
                for childMapping in childMappings {
                    hydrateArray(from: row, with: childMapping, in: &dictionary)
                }
            }

            if let siblingMappings = tableColumnSiblingMappings[table] {
                for siblingMapping in siblingMappings {
                    hydrateArray(from: row, with: siblingMapping, in: &dictionary)
                }
            }
        }
    }

    private func hydrateObject(
        for row: [Codable?],
        with entityMapping: any EntityMapping,
        in array: inout [[String: Any?]]
    ) {
        let table = entityMapping.table.trimmingQuotes

        if let idIndex = tableIDColumnIndexes[table], let id = row[idIndex], !tablesInHydration.contains(table) {
            let id = String(describing: id)
            tablesInHydration.insert(table)

            if let dictionaryIndex = array.firstIndex(where: {
                $0[entityMapping.id.field] as? String == id
            }) {
                var dictionary = array[dictionaryIndex]
                hydrateAll(for: row, with: entityMapping, in: &dictionary)
                array[dictionaryIndex] = dictionary
            } else {
                var dictionary = [String: Any?]()
                hydrateAll(for: row, with: entityMapping, in: &dictionary)
                array.append(dictionary)
            }

            tablesInHydration.remove(table)
        }
    }

    private func hydrateArray(
        from row: [Codable?],
        with mapping: any AssociationMapping,
        in dictionary: inout [String: Any?]
    ) {
        if let entityMapping = entityManager.configuration.mapping(from: mapping.entity) {
            var array = dictionary[mapping.field] as? [[String: Any?]] ?? .init()
            hydrateObject(for: row, with: entityMapping, in: &array)
            dictionary[mapping.field] = array
        }
    }

    private func updateValue(_ value: Codable?, for field: String, in dictionary: inout [String: Any?]) {
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
            if tableColumnIndexes[table] == nil {
                tableColumnIndexes[table] = .init()
            }

            if tableColumnFieldMappings[table] == nil {
                tableColumnFieldMappings[table] = .init()
            }

            if tableColumnParentMappings[table] == nil {
                tableColumnParentMappings[table] = .init()
            }

            if tableColumnChildMappings[table] == nil {
                tableColumnChildMappings[table] = .init()
            }

            if tableColumnSiblingMappings[table] == nil {
                tableColumnSiblingMappings[table] = .init()
            }

            if let entityMapping = entityManager.configuration.mapping(tableName: table) {
                var tables = tables
                tables.remove(table)

                let childMappings = entityMapping.children.filter({
                    tables.contains(entityManager.configuration.mapping(from: $0.entity)!.table.trimmingQuotes)
                })
                tableColumnChildMappings[table] = tableColumnChildMappings[table]!.union(childMappings)

                let siblingMappings = entityMapping.siblings.filter({
                    tables.contains(entityManager.configuration.mapping(from: $0.entity)!.table.trimmingQuotes)
                })
                tableColumnSiblingMappings[table] = tableColumnSiblingMappings[table]!.union(siblingMappings)
            }
        }

        for (index, column) in result.columns.enumerated() {
            if let idColumn = entityManager.configuration.mapping(tableName: column.table)?.id.column, idColumn == column.name {
                tableIDColumnIndexes[column.table] = index
            }

            tableColumnIndexes[column.table]?[column.name] = index

            if let entityMapping = entityManager.configuration.mapping(tableName: column.table) {
                if let fieldMapping = entityMapping.fields.first(where: { $0.column.name == column.name }) {
                    tableColumnFieldMappings[column.table]?[column.name] = fieldMapping
                } else if let parentMapping = entityMapping.parents.first(where: { $0.column.name == column.name }) {
                    tableColumnParentMappings[column.table]?[column.name] = parentMapping
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
