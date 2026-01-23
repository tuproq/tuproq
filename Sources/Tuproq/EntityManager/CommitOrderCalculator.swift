final actor CommitOrderCalculator {
    private var nodes = [String: Node]()
    private var sortedNodes = [String]()

    init() {}

    func addNode(_ node: Node) {
        nodes[node.value] = node
    }

    func hasNode(_ node: Node) -> Bool {
        nodes[node.value] != nil
    }

    func addDependency(_ dependency: Dependency) {
        nodes[dependency.from]?.addDependency(dependency)
    }

    func sort() -> [String] {
        for node in nodes.values {
            if node.state == .notVisited {
                visitNode(node)
            }
        }

        let result = Array(sortedNodes.reversed())

        // Reset state
        nodes.removeAll()
        sortedNodes.removeAll()

        return result
    }

    private func visitNode(_ node: Node) {
        node.state = .inProgress

        for dependency in node.dependencies.values {
            if let adjacentNode = nodes[dependency.to] {
                switch adjacentNode.state {
                case .notVisited: visitNode(adjacentNode)
                case .visited: break
                case .inProgress:
                    handleCycle(
                        node: node,
                        adjacentNode: adjacentNode,
                        dependency: dependency
                    )
                }
            }
        }

        if node.state != .visited {
            node.state = .visited
            sortedNodes.append(node.value)
        }
    }

    private func handleCycle(
        node: Node,
        adjacentNode: Node,
        dependency: Dependency
    ) {
        if let adjacentDependency = adjacentNode.dependencies[node.value],
           adjacentDependency.weight < dependency.weight {
            for adjacentDependencyItem in adjacentNode.dependencies.values {
                if let adjacentDependencyNode = nodes[adjacentDependencyItem.to],
                   adjacentDependencyNode.state == .notVisited {
                    visitNode(adjacentDependencyNode)
                }
            }

            adjacentNode.state = .visited
            sortedNodes.append(adjacentNode.value)
        }
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
            self.value = value
            self.state = state
            self.dependencies = dependencies
        }

        func addDependency(_ dependency: Dependency) {
            dependencies[dependency.to] = dependency
        }
    }

    struct Dependency: Sendable {
        let from: String
        let to: String
        let weight: Int
    }
}
