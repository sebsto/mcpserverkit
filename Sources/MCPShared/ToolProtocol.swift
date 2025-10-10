import MCP

public protocol ToolProtocol<Input, Output>: Sendable {
    associatedtype Input: Decodable
    associatedtype Output: Encodable

    var toolName: String { get }
    var toolDescription: String { get }
    var inputSchema: String { get }

    // a generic handler
    func handle(input: Input) async throws -> Output
}
