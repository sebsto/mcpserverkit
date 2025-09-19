public protocol ToolProtocol<Input, Output>: Sendable {
    associatedtype Input
    associatedtype Output

    var name: String { get }
    var description: String { get }
    var inputSchema: String { get }

    // a generic handler
    func handler(input: Input) async throws -> Output
}

