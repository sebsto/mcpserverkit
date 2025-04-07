import MCP

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A protocol that unifies different types of MCP tools
public protocol UnifiedMCPTool: Sendable {
    var name: String { get }
    var description: String { get }
    var inputSchema: String { get }

    func handle(jsonInput: CallTool.Parameters) async throws -> Encodable
}

/// A unified MCPServer that can handle both homogeneous and heterogeneous tools
public struct MCPServer: Sendable {
    let name: String
    let version: String
    let tools: [any MCPToolProtocol]

    public init(
        name: String,
        version: String,
        tools: [any MCPToolProtocol]
    ) {
        self.name = name
        self.version = version
        self.tools = tools
    }

    /// Create a server with tools
    public static func create(
        name: String,
        version: String,
        tools: [any MCPToolProtocol]
    ) -> MCPServer {
        MCPServer(
            name: name,
            version: version,
            tools: tools
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

    public func startStdioServer() async throws {
        // create the server
        let server = Server(
            name: name,
            version: version,
            capabilities: .init(
                tools: .init()
            )
        )

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

        // start the server with the stdio transport
        try await server.start(transport: StdioTransport())

        await server.waitUntilCompleted()
    }
}
