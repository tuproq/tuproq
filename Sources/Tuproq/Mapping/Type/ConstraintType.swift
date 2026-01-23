public enum ConstraintType: Hashable, Sendable {
    case unique(
        columns: Set<String>,
        index: String? = nil
    )
}
