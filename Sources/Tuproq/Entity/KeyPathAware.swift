@_spi(Reflection) import ReflectionMirror

public protocol KeyPathAware {

}

public extension KeyPathAware {
    static var keyPaths: [String: PartialKeyPath<Self>] {
        var keyPaths = [String: PartialKeyPath<Self>]()
        _forEachFieldWithKeyPath(of: Self.self, options: .classType) { cString, keyPath in
            let name = String(cString: cString, encoding: .utf8)!
            keyPaths[name] = keyPath
            return true
        }

        return keyPaths
    }
}
