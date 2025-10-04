import MCP

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A unified MCPServer that can handle both homogeneous and heterogeneous tools
public struct MCPServer: Sendable {
    let name: String
    let version: String
    let tools: [any ToolProtocol]?
    let prompts: [MCPPrompt]?
    let resources: MCPResourceRegistry?

    public init(
        name: String,
        version: String,
        tools: [any ToolProtocol]?,
        prompts: [MCPPrompt]? = nil,
        resources: MCPResourceRegistry? = nil
    ) {
        self.name = name
        self.version = version
        self.tools = tools
        self.prompts = prompts
        self.resources = resources
    }

    /// Create a server with tools
    public static func create(
        name: String,
        version: String,
        tools: [any ToolProtocol]?,
        prompts: [MCPPrompt]? = nil,
        resources: MCPResourceRegistry? = nil
    ) -> MCPServer {
        MCPServer(
            name: name,
            version: version,
            tools: tools,
            prompts: prompts,
            resources: resources
        )
    }

    /// Create a server with a variadic list of tools
    public static func create(
        name: String,
        version: String,
        tools: any ToolProtocol...
    ) -> MCPServer {
        create(name: name, version: version, tools: tools)
    }

    /// Create a server with a variadic list of prompts
    public static func create(
        name: String,
        version: String,
        prompts: MCPPrompt...
    ) -> MCPServer {
        create(name: name, version: version, tools: nil, prompts: prompts)
    }

    public func startStdioServer() async throws {
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

        // create the server
        let server = Server(
            name: name,
            version: version,
            capabilities: capabilities
        )

        if let tools, tools.count > 0 {
            await registerTools(server, tools: tools)
        }

        if let prompts, prompts.count > 0 {
            await registerPrompts(server, prompts: prompts)
        }

        if let resources, !resources.resources.isEmpty {
            await registerResources(server, resources: resources)
        }

        // start the server with the stdio transport
        try await server.start(transport: StdioTransport())
        await server.waitUntilCompleted()
    }

    public func startHttpServer() async throws {
    }

    private func registerTools(_ server: Server, tools: [any ToolProtocol]) async {
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

    /// Register prompts with the server
    private func registerPrompts(_ server: Server, prompts: [MCPPrompt]) async {
        // register the prompts, part 1 : prompts/list
        await server.withMethodHandler(ListPrompts.self) { params in
            let _prompts = prompts.map { $0.toPrompt() }
            return ListPrompts.Result(prompts: _prompts, nextCursor: nil)
        }

        // register the prompts, part 2 : prompts/get
        await server.withMethodHandler(GetPrompt.self) { params in
            // Check if the prompt name is in our list of prompts
            guard let prompt = prompts.first(where: { $0.name == params.name }) else {
                throw MCPServerError.unknownPrompt(params.name)
            }

            // If arguments are provided, render the prompt
            var messages: [Prompt.Message] = []
            if let arguments = params.arguments {
                let values = arguments.mapValues { value in
                    String(describing: value)
                }
                messages.append(try prompt.toMessage(with: values))
            }

            // If no arguments, return empty messages
            return GetPrompt.Result(description: prompt.description, messages: messages)
        }
    }

    /// Register resources with the server
    private func registerResources(_ server: Server, resources: MCPResourceRegistry) async {
        // Register resources/list handler
        await server.withMethodHandler(ListResources.self) { params in
            let mcpResources = resources.asMCPResources()
            return ListResources.Result(resources: mcpResources, nextCursor: nil)
        }

        // Register resources/read handler
        await server.withMethodHandler(ReadResource.self) { params in
            // Find the resource with the requested URI
            guard let resource = resources.find(uri: params.uri) else {
                throw MCPServerError.resourceNotFound(params.uri)
            }

            // Return the resource content
            return ReadResource.Result(contents: [resource.content])
        }

        // Register resources/templates/list handler
        await server.withMethodHandler(ListResourceTemplates.self) { _ in
            // For now, we don't support resource templates
            ListResourceTemplates.Result(templates: [])
        }
    }
}

/// Extension to MCPServer for working with resources
extension MCPServer {
    /// Registers resources with the server
    /// - Parameter registry: The resource registry to register
    /// - Returns: The server, for chaining
    @discardableResult
    public func registerResources(_ registry: MCPResourceRegistry) -> Self {
        MCPServer(
            name: self.name,
            version: self.version,
            tools: self.tools,
            prompts: self.prompts,
            resources: registry
        )
    }

    /// Create a server with resources
    /// - Parameters:
    ///   - name: The server name
    ///   - version: The server version
    ///   - resources: The resources to register
    /// - Returns: A new MCPServer instance
    public static func create(
        name: String,
        version: String,
        resources: MCPResourceRegistry
    ) -> MCPServer {
        create(name: name, version: version, tools: nil, prompts: nil, resources: resources)
    }

    /// Create a server with tools and resources
    /// - Parameters:
    ///   - name: The server name
    ///   - version: The server version
    ///   - tools: The tools to register
    ///   - resources: The resources to register
    /// - Returns: A new MCPServer instance
    public static func create(
        name: String,
        version: String,
        tools: [any ToolProtocol],
        resources: MCPResourceRegistry
    ) -> MCPServer {
        create(name: name, version: version, tools: tools, prompts: nil, resources: resources)
    }

    /// Create a server with prompts and resources
    /// - Parameters:
    ///   - name: The server name
    ///   - version: The server version
    ///   - prompts: The prompts to register
    ///   - resources: The resources to register
    /// - Returns: A new MCPServer instance
    public static func create(
        name: String,
        version: String,
        prompts: [MCPPrompt],
        resources: MCPResourceRegistry
    ) -> MCPServer {
        create(name: name, version: version, tools: nil, prompts: prompts, resources: resources)
    }
}
