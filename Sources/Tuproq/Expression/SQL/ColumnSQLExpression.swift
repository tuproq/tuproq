class ColumnSQLExpression: SQLExpression, ExpressibleByStringLiteral {
    let name: String
    let alias: String?

    required convenience init(stringLiteral name: String) {
        let components = name.components(separatedBy: " ")

        if components.count == 3, components[1].lowercased() == Kind.as.rawValue.lowercased() {
            self.init(name: components[0], alias: components[2])
        } else {
            self.init(name: name)
        }
    }

    init(name: String, alias: String? = nil) {
        self.name = name
        self.alias = alias
        var raw = name

        if let alias {
            raw += " \(Kind.as) \(alias)"
        }

        super.init(raw: raw)
    }
}
