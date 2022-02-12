extension String {
    var droppingLeadingSlash: String {
        first == "/" ? String(dropFirst()) : self
    }
}
