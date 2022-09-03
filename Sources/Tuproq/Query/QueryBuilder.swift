public protocol QueryBuilder: AnyObject {
    associatedtype E: Expression
    associatedtype Q: Query

    var expressions: [E] { set get }

    func getQuery() -> Q
}
