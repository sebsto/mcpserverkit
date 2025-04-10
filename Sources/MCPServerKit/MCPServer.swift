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
    let tools: [any MCPToolProtocol]?
    let prompts: [MCPPrompt]?

    public init(
        name: String,
        version: String,
        tools: [any MCPToolProtocol]?,
        prompts: [MCPPrompt]? = nil
    ) {
        self.name = name
        self.version = version
        self.tools = tools
        self.prompts = prompts
    }

    /// Create a server with tools
    public static func create(
        name: String,
        version: String,
        tools: [any MCPToolProtocol]?,
        prompts: [MCPPrompt]? = nil
    ) -> MCPServer {
        MCPServer(
            name: name,
            version: version,
            tools: tools,
            prompts: prompts
        )
    }

    /// Create a server with a variadic list of tools
    public static func create(
        name: String,
        version: String,
        tools: any MCPToolProtocol...
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

        // start the server with the stdio transport
        try await server.start(transport: StdioTransport())
        await server.waitUntilCompleted()
    }

    private func registerTools(_ server: Server, tools: [any MCPToolProtocol]) async {
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
    public func registerPrompts(_ server: Server, prompts: [MCPPrompt]) async {
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
}
