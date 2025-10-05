public protocol ToolProtocol<Input, Output>: Sendable {
    associatedtype Input: Decodable
    associatedtype Output: Encodable

    var name: String { get }
    var description: String { get }
    var inputSchema: String { get }

    // a generic handler
    func handle(input: Input) async throws -> Output
}
