import MCP

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A version of MCPServer that can work with tools of different input and output types
public struct JSONBasedMCPServer: Sendable {
    let name: String
    let version: String
    let tools: [JSONBasedMCPTool]

    public init(
        name: String,
        version: String,
        tools: [JSONBasedMCPTool]
    ) {
        self.name = name
        self.version = version
        self.tools = tools
    }

    /// Helper method to find a tool by name
    func findTool(name: String) -> JSONBasedMCPTool? {
        tools.first { $0.name == name }
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

//extension JSONBasedMCPServer {
//    /// Create a server with a variadic list of tools
//    public static func create(name: String, version: String, tools: JSONBasedMCPTool...) -> JSONBasedMCPServer {
//        return JSONBasedMCPServer(name: name, version: version, tools: tools)
//    }
//
//    /// Create a server with a variadic list of tools
//    public static func create<Input, Output>(name: String, version: String, tools: MCPTool<Input, Output>...) -> JSONBasedMCPServer {
//        return JSONBasedMCPServer(name: name, version: version, tools: tools.map { JSONMCPToolAdapter($0) })
//    }
//}
