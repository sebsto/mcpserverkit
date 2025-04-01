import Foundation

/// Core functionality for the MCP protocol
public struct MCPCore {
    /// Create a new MCP server
    public static func createServer(name: String) async throws -> VaporMCPServer {
        return try await VaporMCPServer(name: name)
    }
}
