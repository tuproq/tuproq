public enum ConstraintType: Hashable {
    case unique(columns: Set<String>, index: String? = nil)
}
