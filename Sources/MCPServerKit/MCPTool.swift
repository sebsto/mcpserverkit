import MCP

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A MCPTool implementation that deals with JSON input and output
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
}
