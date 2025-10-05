import Logging
import MCP
import ServerShared

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A unified MCPServer that can handle both homogeneous and heterogeneous tools
public struct MCPServer: Sendable {

    let server: Server
    let transport: MCPTransport

    let name: String
    let version: String
    let tools: [any ToolProtocol]?
    let prompts: [MCPPrompt]?
    let resources: MCPResourceRegistry?

    let logger: Logger

    public init(
        name: String,
        version: String,
        transport: MCPTransport,
        tools: [any ToolProtocol]?,
        prompts: [MCPPrompt]? = nil,
        resources: MCPResourceRegistry? = nil,
        logger: Logger
    ) {
        self.name = name
        self.version = version
        self.transport = transport
        self.tools = tools
        self.prompts = prompts
        self.resources = resources
        self.logger = logger

        // create the server
        server = Server(
            name: name,
            version: version,
            capabilities: MCPServer.capabilities(tools, prompts, resources)
        )
    }

    /// Create a server for Stdio transport
    public static func withStdioMCPServer(
        name: String,
        version: String,
        tools: [any ToolProtocol]?,
        prompts: [MCPPrompt]? = nil,
        resources: MCPResourceRegistry? = nil,
        logger: Logger,
        _ body: @Sendable (MCPServer) async throws -> Void
    ) async throws {
        try await withMCPServer(
            name: name,
            version: version,
            transport: .stdio,
            tools: tools,
            prompts: prompts,
            resources: resources,
            logger: logger,
            body
        )
    }

    /// Create a server for Stdio transport
    public static func withHttpMCPServer(
        name: String,
        version: String,
        tools: [any ToolProtocol]?,
        prompts: [MCPPrompt]? = nil,
        resources: MCPResourceRegistry? = nil,
        logger: Logger,
        _ body: @Sendable (MCPServer) async throws -> Void
    ) async throws {
        try await withMCPServer(
            name: name,
            version: version,
            transport: .http,
            tools: tools,
            prompts: prompts,
            resources: resources,
            logger: logger,
            body
        )
    }

    /// Create a server for Stdio transport
    public static func withMCPServer(
        name: String,
        version: String,
        transport: MCPTransport,
        tools: [any ToolProtocol]?,
        prompts: [MCPPrompt]? = nil,
        resources: MCPResourceRegistry? = nil,
        logger: Logger = Logger(label: "MCPServer"),
        _ body: @Sendable (MCPServer) async throws -> Void
    ) async throws {
        let server = MCPServer(
            name: name,
            version: version,
            transport: transport,
            tools: tools,
            prompts: prompts,
            resources: resources,
            logger: logger,
        )
        return try await body(server)
    }

    package static func capabilities(
        _ tools: [any ToolProtocol]?,
        _ prompts: [MCPPrompt]?,
        _ resources: MCPResourceRegistry?
    ) -> Server.Capabilities {
        var capabilities = Server.Capabilities()
        if let tools, tools.count > 0 {
            capabilities.tools = .init()
        }
        if let prompts, prompts.count > 0 {
            capabilities.prompts = .init()
        }
        if let resources, !resources.resources.isEmpty {
            capabilities.resources = .init()
        }
        return capabilities
    }

    package func registerTools(_ server: Server, tools: [any ToolProtocol]) async {
        // register the tools, part 1 : tools/list
        await server.withMethodHandler(ListTools.self) { params in
            let _tools = try tools.map { tool in
                Tool(
                    name: tool.name,
                    description: tool.description,
                    inputSchema: try JSONDecoder().decode(
                        Value.self,
                        from: tool.inputSchema.data(using: .utf8)!
                    )
                )
            }

            return ListTools.Result(tools: _tools, nextCursor: nil)
        }

        // register the tools, part 2 : tools/call
        await server.withMethodHandler(CallTool.self) { params in
            // Check if the tool name is in our list of tools
            guard let tool = tools.first(where: { $0.name == params.name }) else {
                throw MCPServerError.unknownTool(params.name)
            }

            // call the tool with JSON input
            let output = try await tool.handle(jsonInput: params)

            // return the result
            return CallTool.Result(content: [.text(String(describing: output))])
        }
    }
}
