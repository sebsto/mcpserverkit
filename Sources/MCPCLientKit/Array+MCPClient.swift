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
    public func cleanup() async {
        // cannot use forEach because it's not async
        for mcpClient in self {
            await mcpClient.disconnectAndTerminateServerProcess()
        }
    }

    // // return a single MCP client by tool name
    public func clientForTool(named toolName: String) -> Client? {
        self.first { $0.hasTool(named: toolName) }?.client
    }

    // public init(from: URL, logger: Logger) async throws {
    public static func create(from: URL, logger: Logger) async throws -> [MCPClient] {
        let fileManager = FileManager.default
        let mcpFileURL = from.appendingPathComponent("mcp.json")

        // Check if the mcp.json file exists
        guard fileManager.fileExists(atPath: mcpFileURL.path) else {
            throw MCPToolError.fileNotFound(path: mcpFileURL.path)
        }

        // Read the mcp.json file and parse it
        let mcpData = try Data(contentsOf: mcpFileURL)
        let mcpJSON = try JSONDecoder().decode(MCPConfiguration.self, from: mcpData)

        // Create MCP clients for each tool in the mcp.json file
        var clients = [MCPClient]()
        for (toolName, toolConfig) in mcpJSON.mcpServers {
            let client = try await MCPClient(
                with: toolConfig,
                name: toolName,
                for: toolName,
                logger: logger
            )
            clients.append(client)
        }
        return clients
    }
    public func callTool(
        name toolName: String,
        arguments: [String: MCPValue],
        logger: Logger = Logger(label: "MCPClient")
    ) async throws -> String {

        guard let client = self.clientForTool(named: toolName) else {
            throw MCPToolError.toolNotFound(name: toolName)
        }
        logger.trace(
            "Tool found, going to call it",
            metadata: ["toolName": "\(toolName)", "arguments": "\(arguments)"]
        )

        // call the tool with the provided arguments
        let (content, isError) = try await client.callTool(name: toolName, arguments: arguments)
        logger.debug(
            "Tool called",
            metadata: ["toolName": "\(toolName)"]
        )
        logger.trace(
            "Tool result",
            metadata: ["content": "\(content)", "isError": "\(String(describing: isError))"]
        )

        guard let c = content.first,
            case let .text(text) = c
        else {
            logger.error("Tool returned an unsupported response (something else than text)")
            throw MCPToolError.unsupportedToolResponse
        }
        // Check if the tool returned an error
        guard isError == nil
        else {
            logger.error("Tool returned an error")
            throw MCPToolError.toolError(message: text)
        }

        return text
    }
}
