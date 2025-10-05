import MCP

extension MCPServer {
    package func startStdioServer() async throws {
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
}
