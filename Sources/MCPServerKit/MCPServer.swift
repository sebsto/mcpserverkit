import MCP

#if canImport(FoundationEssentials)
import FoundatioNEssentials
#else
import Foundation
#endif

//TODO: add compliance to Swift Service Lifecycle
//TODO: add a logger into the game
public struct MCPServer<Input: Decodable, Output>: Sendable {

    let name: String
    let version: String
    let tools: [any MCPToolProtocol<Input, Output>]

    public init(
        name: String,
        version: String,
        tools: [any MCPToolProtocol<Input, Output>]
    ) {
        self.name = name
        self.version = version
        self.tools = tools
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

            // the tool converts the parameters to its expected input type
            let input = try await tool.convert(params)

            // call the tool
            let output = try await tool.handler(input)

            // return the result
            //FIXME: should we return the output as JSON object?
            return CallTool.Result(content: [.text(String(describing: output))])
        }

        // start the server with the stdio transport
        try await server.start(transport: StdioTransport())

        await server.waitUntilCompleted()

    }
}
