import Foundation

public class EntityManager: ObjectManager {
    public typealias ChangeSet = [String: (Any?, Any?)] // [property: (oldValue, newValue)]

    private var entityChangeSets = [AnyHashable: ChangeSet]()
    private var entityInsertions = [AnyHashable: AnyEntity]()
    private var entityUpdates = [AnyHashable: AnyEntity]()
    private var entityDeletions = [AnyHashable: AnyEntity]()
    private var entityStates = [AnyHashable: EntityState]()
    private var entityIdentifiers = [AnyHashable: [AnyHashable]]()
    private var identityMap = [String: [AnyHashable: AnyEntity]]()
    private var repositories = [String: AnyRepository]()

    public init() {}

    public func detach<E: Entity>(_ entity: E) {
        var entities = [AnyHashable: AnyEntity]()
        detach(entity, visited: &entities)
    }

    private func detach<E: Entity>(_ entity: E, visited entities: inout [AnyHashable: AnyEntity]) {
        let entityID = entity.id
        guard entities[entityID] == nil else { return }
        entities[entityID] = AnyEntity(entity)
        let entityState = entityStates[entityID]

        // TODO: implement
    }

    public func find<E: Entity, I: Hashable>(_ entityType: E.Type, id: I) async throws -> E? {
        // TODO: implement
        return nil
    }

    public func flush() async throws {
        // TODO: implement
    }

    public func flush<E: Entity>(_ entity: E) async throws {
        // TODO: implement
    }

    public func getRepository<R: Repository>(_ repositoryType: R.Type) -> R {
        let entityType = String(describing: repositoryType.EntityType)

        if let repository = repositories[entityType] {
            return repository.repository as! R
        }

        let repository = R()
        repositories[entityType] = AnyRepository(repository)

        return repository
    }

    public func merge<E: Entity>(_ entity: E) {
        // TODO: implement
    }

    public func persist<E: Entity>(_ entity: E) throws {
        var entities = [AnyHashable: AnyEntity]()
        try persist(entity, visited: &entities)
    }

    private func persist<E: Entity>(_ entity: E, visited entities: inout [AnyHashable: AnyEntity]) throws {
        let entityID = entity.id
        guard entities[entityID] == nil else { return }
        entities[entityID] = AnyEntity(entity)
        let entityState = entityStates[entityID]

        switch entityState {
        case .detached: throw NSError()
        case .managed: break
        case .new:
            entityInsertions[entityID] = AnyEntity(entity)
            addToIdentityMap(entity)
        case .removed:
            entityDeletions.removeValue(forKey: entityID)
            addToIdentityMap(entity)
            entityStates[entityID] = .managed
        default:
            entityInsertions[entityID] = AnyEntity(entity)
            addToIdentityMap(entity)
            entityStates[entityID] = .new
        }
    }

    public func refresh<E>(_ entity: E) throws where E : Entity {
        var entities = [AnyHashable: AnyEntity]()
        try refresh(entity, visited: &entities)
    }

    private func refresh<E: Entity>(_ entity: E, visited entities: inout [AnyHashable: AnyEntity]) throws {
        let entityID = entity.id
        guard entities[entityID] == nil else { return }
        entities[entityID] = AnyEntity(entity)
        let entityState = entityStates[entityID]

        // TODO: implement
    }

    public func remove<E: Entity>(_ entity: E) {
        var entities = [AnyHashable: AnyEntity]()
        remove(entity, visited: &entities)
    }

    private func remove<E: Entity>(_ entity: E, visited entities: inout [AnyHashable: AnyEntity]) {
        let entityID = entity.id
        guard entities[entityID] == nil else { return }
        entities[entityID] = AnyEntity(entity)
        let entityState = entityStates[entityID]

        switch entityState {
        case .managed:
            entityDeletions[entityID] = AnyEntity(entity)
            entityStates[entityID] = .removed
        case .new:
            entityInsertions.removeValue(forKey: entityID)
            removeFromIdentityMap(entity)
            entityStates.removeValue(forKey: entityID)
        default: break
        }
    }

    private func addToIdentityMap<E: Entity>(_ entity: E) {
        let entityID = entity.id
        let entityType = String(describing: type(of: entity))
        identityMap[entityType]?[entityID] = AnyEntity(entity)
    }

    private func isInIdentityMap<E: Entity>(_ entity: E) -> Bool {
        let entityID = entity.id
        let entityType = String(describing: type(of: entity))

        return identityMap[entityType]?[entityID] != nil
    }

    private func removeFromIdentityMap<E: Entity>(_ entity: E) {
        let entityID = entity.id
        let entityType = String(describing: type(of: entity))
        identityMap[entityType]?.removeValue(forKey: entityID)
    }
}

extension EntityManager {
    public enum EntityState {
        case detached
        case new
        case managed
        case removed
    }
}
