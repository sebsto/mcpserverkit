import MCP

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A MCPTool implementation that deals with JSON input and output
// @available(*, deprecated, message: "Use the @Tool macro instead" )
/// THIS IS ONLY USED IN UNIT TEST TO AVOID USING THE MACRO THERE
public struct MCPTool<Input: Decodable, Output: Encodable>: ToolProtocol {
    public let toolName: String
    public let toolDescription: String
    public let inputSchema: String
    public let body: @Sendable (Input) async throws -> Output

    public init(
        name: String,
        description: String,
        inputSchema: String,
        body: @Sendable @escaping (Input) async throws -> Output
    ) {
        self.toolName = name
        self.toolDescription = description
        self.inputSchema = inputSchema
        self.body = body
    }

    public func handle(input: Input) async throws -> Output {
        try await self.body(input)
    }

    public init() { fatalError("Always use the initializer with name, description, inputSchema, and body") }
}
