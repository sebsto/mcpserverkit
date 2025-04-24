import Logging
import MCP
import System

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public struct MCPClient {

    public let name: String
    private let process: Process
    public let client: Client
    private let logger: Logger
    package let tools: [Tool]

    package init(
        with toolConfig: MCPConfiguration.ToolConfiguration,
        name: String,
        for server: String,
        version: String = "1.0.0",
        logger: Logger
    ) async throws {
        self.name = name
        self.client = Client(name: name, version: version)
        self.logger = logger

        logger.trace(
            "Launching process",
            metadata: [
                "command": "\(toolConfig.command)",
                "arguments": "\(toolConfig.args.joined(separator: " "))",
            ]
        )

        // Create pipes for the server input and output
        let serverInputPipe = Pipe()
        let serverOutputPipe = Pipe()
        let serverInput: FileDescriptor = FileDescriptor(
            rawValue: serverInputPipe.fileHandleForWriting.fileDescriptor
        )
        let serverOutput: FileDescriptor = FileDescriptor(
            rawValue: serverOutputPipe.fileHandleForReading.fileDescriptor
        )

        self.process = Process()
        process.executableURL = URL(fileURLWithPath: toolConfig.command)
        process.arguments = toolConfig.args
        process.standardInput = serverInputPipe
        process.standardOutput = serverOutputPipe

        let transport = StdioTransport(
            input: serverOutput,
            output: serverInput,
            logger: logger
        )

        try process.run()
        logger.trace("Process launched")

        try await client.connect(transport: transport)
        logger.trace("Connected to MCP server")

        // Initialize the connection
        let result = try await client.initialize()
        logger.trace("Connection initialized", metadata: ["result": "\(result)"])

        // collect the list of tools available in the MCP server
        // var cursor: String? = nil
        (self.tools, _) = try await client.listTools()
        logger.trace("Available tools", metadata: ["toolsCount": "\(self.tools.count)"])
    }

    public init(
        with serverConfigFile: URL,
        name: String,
        for server: String,
        version: String = "1.0.0",
        logger: Logger
    ) async throws {

        let toolConfig = try MCPClient.getMCPToolCommand(in: serverConfigFile, for: server)

        self = try await .init(with: toolConfig, name: name, for: server, logger: logger)
    }

    public func disconnectAndTerminateServerProcess() async {
        if self.process.isRunning {
            await self.client.disconnect()
            self.process.terminate()
        }
    }

    /// Returns the tool with the given name, or nil if not found.
    /// - Parameter toolName: The name of the tool to look up
    /// - Returns: The tool if found, nil otherwise
    /// - Note: This method checks the list of tools available in the MCP server.
    public func getTool(named toolName: String) -> Tool? {
        self.tools.first { $0.name == toolName }
    }
    /// Checks if the tool with the given name exists in the list of tools.
    /// - Parameter toolName: The name of the tool to check
    /// - Returns: A boolean indicating whether the tool exists
    /// - Note: This method checks the list of tools available in the MCP server.
    public func hasTool(named toolName: String) -> Bool {
        self.tools.map { $0.name }.contains(toolName)
    }

    /// Reads a mcp.json file and returns the command and arguments for a given tool name.
    /// - Parameter
    ///      toolName: The name of the tool to look up in the mcp.json file
    ///      mcpFileURL: The URL of the mcp.json file
    /// - Returns: The tool configuration containing the command and arguments
    /// - Throws: MCPToolError if the file can't be read or parsed, or if the tool name is not found
    private static func getMCPToolCommand(
        in mcpFileURL: URL,
        for toolName: String
    ) throws -> MCPConfiguration.ToolConfiguration {

        // Read the mcp.json file
        do {
            let mcpData = try Data(contentsOf: mcpFileURL)

            // Parse the JSON
            let mcpJSON = try JSONDecoder().decode(MCPConfiguration.self, from: mcpData)

            // Look for the tool
            guard let toolConfig = mcpJSON.mcpServers[toolName] else {
                throw MCPToolError.toolNotFound(name: toolName)
            }

            return toolConfig
        } catch is DecodingError {
            throw MCPToolError.invalidFormat(reason: "JSON structure does not match expected format")
        } catch let error as MCPToolError {
            throw error
        } catch {
            throw MCPToolError.fileNotFound(path: mcpFileURL.path)
        }
    }
}

/// Structure representing the MCP configuration file format
package struct MCPConfiguration: Decodable {
    let mcpServers: [String: ToolConfiguration]

    package struct ToolConfiguration: Decodable {
        let command: String
        let args: [String]
    }
}

/// Custom error type for MCP tool command operations
public enum MCPToolError: Swift.Error, CustomStringConvertible {
    case fileNotFound(path: String)
    case invalidFormat(reason: String)
    case toolNotFound(name: String)
    case toolError(message: String)
    case unsupportedToolResponse

    public var description: String {
        switch self {
        case .fileNotFound(let path):
            return "Could not read MCP configuration file at \(path)"
        case .invalidFormat(let reason):
            return "Invalid MCP configuration format: \(reason)"
        case .toolNotFound(let name):
            return "Tool '\(name)' not found in MCP configuration"
        case .toolError(let message):
            return "Tool error: \(message)"
        case .unsupportedToolResponse:
            return "Only text responses are supported at the moment"
        }
    }
}
