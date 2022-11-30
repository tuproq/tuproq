final class CommitOrderCalculator {
    private var nodes = [String: Node]()
    private var sortedNodes = [String]()

    init() {}

    func hasNode(_ node: Node) -> Bool {
        nodes[node.value] != nil
    }

    func addNode(_ node: Node) {
        nodes[node.value] = node
    }

    func addDependency(_ dependency: Dependency) {
        nodes[dependency.from]?.dependencies[dependency.to] = dependency
    }

    func sort() -> [String] {
        for node in nodes.values {
            var node = node

            if node.state != .notVisited {
                continue
            }

            visit(node: &node)
        }

        let sortedNodes = sortedNodes
        nodes.removeAll()
        self.sortedNodes.removeAll()

        return sortedNodes.reversed()
    }

    func visit(node: inout Node) {
        node.state = .inProgress

        for dependency in node.dependencies.values {
            if var adjacentNode = nodes[dependency.to] {
                switch adjacentNode.state {
                case .notVisited: visit(node: &adjacentNode)
                case .visited: break
                case .inProgress:
                    if let adjacentDependency = adjacentNode.dependencies[node.value],
                       adjacentDependency.weight < dependency.weight {
                        for adjacentDependency in adjacentNode.dependencies.values {
                            if var adjacentDependencyNode = nodes[adjacentDependency.to],
                               adjacentDependencyNode.state == .notVisited {
                                visit(node: &adjacentDependencyNode)
                            }

                            adjacentNode.state = .visited
                            sortedNodes.append(adjacentNode.value)
                        }
                    }
                }
            }
        }

        if node.state != .visited {
            node.state = .visited
            sortedNodes.append(node.value)
        }
    }
}

extension CommitOrderCalculator {
    struct Node {
        var state: State = .notVisited
        var value: String
        var dependencies = [String: Dependency]()

        enum State {
            case notVisited
            case inProgress
            case visited
        }
    }

    struct Dependency {
        var from: String
        var to: String
        var weight: Int
    }
}
