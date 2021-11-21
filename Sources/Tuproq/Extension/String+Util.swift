extension String {
    func dropLeadingSlash() -> String {
        first == "/" ? String(dropFirst()) : self
    }
}
