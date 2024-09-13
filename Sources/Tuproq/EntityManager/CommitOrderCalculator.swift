final class CommitOrderCalculator {
    private var nodes = [String: Node]()
    private var sortedNodes = [String]()

    init() {}

    func addDependency(_ dependency: Dependency) {
        nodes[dependency.from]?.addDependency(dependency)
    }

    func addNode(_ node: Node) {
        nodes[node.value] = node
    }

    func hasNode(_ node: Node) -> Bool {
        nodes[node.value] != nil
    }

    func visitNode(_ node: Node) {
        node.state = .inProgress

        for dependency in node.dependencies.values {
            if let adjacentNode = nodes[dependency.to] {
                switch adjacentNode.state {
                case .notVisited: visitNode(adjacentNode)
                case .visited: break
                case .inProgress:
                    if let adjacentDependency = adjacentNode.dependencies[node.value],
                       adjacentDependency.weight < dependency.weight {
                        for adjacentDependency in adjacentNode.dependencies.values {
                            if let adjacentDependencyNode = nodes[adjacentDependency.to],
                               adjacentDependencyNode.state == .notVisited {
                                visitNode(adjacentDependencyNode)
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

    func sort() -> [String] {
        for node in nodes.values {
            if node.state != .notVisited {
                continue
            }

            visitNode(node)
        }

        let sortedNodes = sortedNodes
        nodes.removeAll()
        self.sortedNodes.removeAll()

        return sortedNodes.reversed()
    }
}

extension CommitOrderCalculator {
    final class Node {
        let value: String
        var state: State
        private(set) var dependencies: [String: Dependency]

        enum State {
            case notVisited
            case inProgress
            case visited
        }

        init(
            value: String,
            state: State = .notVisited,
            dependencies: [String: Dependency] = .init()
        ) {
            self.state = state
            self.value = value
            self.dependencies = dependencies
        }

        func addDependency(_ dependency: Dependency) {
            dependencies[dependency.to] = dependency
        }
    }
}

extension CommitOrderCalculator {
    final class Dependency {
        let from: String
        let to: String
        let weight: Int

        init(
            from: String,
            to: String,
            weight: Int
        ) {
            self.from = from
            self.to = to
            self.weight = weight
        }
    }
}
