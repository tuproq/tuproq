import Foundation

final actor CommitOrderCalculator {
    private var nodesMap = [String: Node]()
    private var sortedNodes = [String]()

    func addNode(_ node: Node) {
        if !hasNode(node) {
            nodesMap[node.rawValue] = node
        }
    }

    func hasNode(_ node: Node) -> Bool {
        nodesMap[node.rawValue] != nil
    }

    func addDependency(_ dependency: Dependency) async {
        if let node = nodesMap[dependency.from] {
            await node.addDependency(dependency)
        }
    }

    func sort() async -> [String] {
        for node in nodesMap.values {
            if await node.getState() == .notVisited {
                await visitNode(node)
            }
        }

        let result = Array(sortedNodes.reversed())
        nodesMap.removeAll()
        sortedNodes.removeAll()

        return result
    }

    private func visitNode(_ node: Node) async {
        await node.setState(.inProgress)

        for dependency in await node.getDependenciesMap().values {
            if let adjacentNode = nodesMap[dependency.to] {
                let state = await adjacentNode.getState()

                switch state {
                case .notVisited: await visitNode(adjacentNode)
                case .visited: break
                case .inProgress:
                    await handleCycle(
                        node: node,
                        adjacentNode: adjacentNode,
                        dependency: dependency
                    )
                }
            }
        }

        if await node.getState() != .visited {
            await node.setState(.visited)
            sortedNodes.append(node.rawValue)
        }
    }

    private func handleCycle(
        node: Node,
        adjacentNode: Node,
        dependency: Dependency
    ) async {
        guard let adjacentDependency = await adjacentNode.getDependenciesMap()[node.rawValue],
              adjacentDependency.weight < dependency.weight
        else { return }

        for adjacentDependencyItem in await adjacentNode.getDependenciesMap().values {
            if let nextNode = nodesMap[adjacentDependencyItem.to],
               await nextNode.getState() == .notVisited {
                await visitNode(nextNode)
            }
        }

        await adjacentNode.setState(.visited)
        sortedNodes.append(adjacentNode.rawValue)
    }
}

extension CommitOrderCalculator {
    final actor Node: RawRepresentable {
        let rawValue: String

        private var state: State = .notVisited
        private var dependenciesMap = [String: Dependency]()

        enum State {
            case notVisited
            case inProgress
            case visited
        }

        init(rawValue: String) {
            self.rawValue = rawValue
        }

        func getState() -> State {
            state
        }

        func setState(_ state: State) {
            self.state = state
        }

        func addDependency(_ dependency: Dependency) {
            dependenciesMap[dependency.to] = dependency
        }

        func getDependenciesMap() -> [String: Dependency] {
            dependenciesMap
        }
    }

    struct Dependency: Sendable {
        let from: String
        let to: String
        let weight: Int
    }
}
