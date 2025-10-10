import Logging
import MCP

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension Array where Element == MCPClient {

    /// Return a list of all tools available in this MCP client
    public func listToolNames() -> [String] {
        var result = [String]()
        self.forEach { tool in
            result.append(tool.name)
        }
        return result
    }
    /// Return a single MCP client by tool name
    /// this method is async because `hasTool(named:)` is isolated to its actor
    public func clientForTool(named toolName: String) async -> Client? {
        for client in self {
            if await client.hasTool(named: toolName) {
                return client.client
            }
        }
        return nil
    }

}
