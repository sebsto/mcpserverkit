import Logging
import MCP

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension Array where Element == MCPClient {

    // return a list of all tools available in the MCP clients
    public func listTools() async throws -> [String] {
        var result = [String]()
        self.forEach { client in
            result.append(contentsOf: client.tools.map { "\(client.name): \($0.name)" })
        }
        return result
    }

    // cleanly terminate all MCP servers
    // public func cleanup() async {
    //     // cannot use forEach because it's not async
    //     for mcpClient in self {
    //         await mcpClient.disconnectAndTerminateServerProcess()
    //     }
    // }

    // // return a single MCP client by tool name
    public func clientForTool(named toolName: String) -> Client? {
        self.first { $0.hasTool(named: toolName) }?.client
    }

}
