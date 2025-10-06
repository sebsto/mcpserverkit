import MCP
import Testing

@testable import MCPServerKit

@Suite("MCPServer Resource Tests")
struct MCPServerResourceTests {

    @Test("Create Server With Resources")
    func testCreateServerWithResources() async throws {
        let registry = MCPResourceRegistry()
        registry.add(
            MCPResource.text(
                name: "Documentation",
                uri: "docs://api",
                content: "# API Documentation",
                mimeType: .markdown
            )
        )

        try await MCPServer.withMCPServer(
            name: "ResourceServer",
            version: "1.0.0",
            transport: .stdio,
            resources: registry
        ) { server in
            #expect(server.name == "ResourceServer")
            #expect(server.version == "1.0.0")
            #expect(server.resources.resources.count == 1)
            #expect(server.resources.resources[0].resource.name == "Documentation")
        }

    }

    @Test("Create Server With Tools And Resources")
    func testCreateServerWithToolsAndResources() async throws {
        // Create a tool
        let tool = MCPTool<String, String>(
            name: "echo",
            description: "Echo the input",
            inputSchema: """
                {
                    "type": "object",
                    "properties": {
                        "message": {
                            "type": "string",
                            "description": "Message to echo"
                        }
                    },
                    "required": ["message"]
                }
                """,
            body: { input in
                input
            }
        )

        // Create resources
        let registry = MCPResourceRegistry()
        registry.add(
            MCPResource.text(
                name: "Documentation",
                uri: "docs://api",
                content: "# API Documentation",
                mimeType: .markdown
            )
        )

        // Create server with both tools and resources
        try await MCPServer.withMCPServer(
            name: "ToolsAndResourcesServer",
            version: "1.0.0",
            transport: .stdio,
            tools: [tool],
            resources: registry
        ) { server in
            #expect(server.name == "ToolsAndResourcesServer")
            #expect(server.version == "1.0.0")
            #expect(server.tools != nil)
            #expect(server.tools?.count == 1)
            #expect(server.tools?[0].name == "echo")
            #expect(server.resources.resources.count == 1)
            #expect(server.resources.resources[0].resource.name == "Documentation")
        }
    }

    @Test("Register Resources With Server")
    func testRegisterResourcesWithServer() async throws {
        // Create a server without resources
        try await MCPServer.withMCPServer(
            name: "EmptyServer",
            version: "1.0.0",
            transport: .stdio,
            tools: [any ToolProtocol]()
        ) { server in
            // Create resources
            let registry = MCPResourceRegistry()
            registry.add(
                MCPResource.text(
                    name: "Documentation",
                    uri: "docs://api",
                    content: "# API Documentation",
                    mimeType: .markdown
                )
            )
            // Register resources with the server
            await server.registerResources(resources: registry)

            #expect(server.name == "EmptyServer")
            #expect(server.version == "1.0.0")
            #expect(server.resources.resources.count == 1)
            #expect(server.resources.resources[0].resource.name == "Documentation")
        }

    }
}
