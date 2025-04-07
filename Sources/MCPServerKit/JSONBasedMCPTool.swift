import MCP

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A protocol for MCP tools that work with JSON-based input and output
public protocol JSONBasedMCPTool: UnifiedMCPTool {
    var name: String { get }
    var description: String { get }
    var inputSchema: String { get }

    /// Handle JSON input and return a result that can be converted to JSON
    func handle(jsonInput: CallTool.Parameters) async throws -> Encodable
}

/// An adapter that wraps any MCPToolProtocol to make it conform to JSONBasedMCPTool
public struct JSONMCPToolAdapter<I, O: Encodable>: JSONBasedMCPTool {
    private let tool: any MCPToolProtocol<I, O>

    public init(_ tool: any MCPToolProtocol<I, O>) where O: Encodable {
        self.tool = tool
    }

    public var name: String { tool.name }
    public var description: String { tool.description }
    public var inputSchema: String { tool.inputSchema }

    public func handle(jsonInput: CallTool.Parameters) async throws -> Encodable {
        // Convert JSON input to the tool's input type
        let input = try await tool.convert(jsonInput)

        // Process with the original tool
        let output = try await tool.handler(input)

        // Return the output
        return output
    }
}

// Extension to easily create a JSON-based tool from an MCPTool
extension MCPToolProtocol where Output: Encodable {
    public func asJSONTool() -> JSONBasedMCPTool {
        JSONMCPToolAdapter(self)
    }
}
