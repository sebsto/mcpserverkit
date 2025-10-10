import Logging
import MCP
import MCPShared

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension MCPClient {

	/// Convert all our MCP Tools to ToolProtocol know by this library (and the Agent)
	public func asTools() -> [any ToolProtocol] {
		self.tools.map { MCPToolWrapper(client: self, tool: $0) }
	} 

}

struct MCPToolWrapper: ToolProtocol {
    typealias Input = [String: MCPValue]
    typealias Output = String

    var name: String { tool.name }
    var description: String { tool.description }
    var inputSchema: String {
        guard let schemaData = try? JSONSerialization.data(withJSONObject: tool.inputSchema as Any),
              let schemaString = String(data: schemaData, encoding: .utf8) else {
            return "{}"
        }
        return schemaString
    }

    let client: MCPClient
    let tool: Tool

    func handle(input: Input) async throws -> Output {
        return try await client.invokeTool(name: self.name, arguments: input)
    }
}