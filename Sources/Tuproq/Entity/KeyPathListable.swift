public protocol KeyPathListable {
    var keyPaths: [String: PartialKeyPath<Self>] { get }
}

extension KeyPathListable {
    public var keyPaths: [String: PartialKeyPath<Self>] {
        var keyPaths = [String: PartialKeyPath<Self>]()
        let mirror = Mirror(reflecting: self)

        for case (let key?, _) in mirror.children {
            keyPaths[key.droppingLeadingUnderscore] = \Self.[descendant: key] as PartialKeyPath
        }

        return keyPaths
    }

    private subscript(descendant key: String) -> Any {
        Mirror(reflecting: self).descendant(key)!
    }
}
