import MCP
import Testing

@testable import MCPServerKit

@Suite("MCPServer Resource Tests")
struct MCPServerResourceTests {

    @Test("Create Server With Resources")
    func testCreateServerWithResources() {
        let registry = MCPResourceRegistry()
        registry.add(
            MCPResource.text(
                name: "Documentation",
                uri: "docs://api",
                content: "# API Documentation",
                mimeType: .markdown
            )
        )

        let server = MCPServer.create(
            name: "ResourceServer",
            version: "1.0.0",
            resources: registry
        )

        #expect(server.name == "ResourceServer")
        #expect(server.version == "1.0.0")
        #expect(server.resources != nil)
        #expect(server.resources?.resources.count == 1)
        #expect(server.resources?.resources[0].resource.name == "Documentation")
    }

    @Test("Create Server With Tools And Resources")
    func testCreateServerWithToolsAndResources() {
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
            converter: { params in
                try MCPTool<String, String>.extractParameter(params, name: "message")
            },
            body: { input in
                return input
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
        let server = MCPServer.create(
            name: "ToolsAndResourcesServer",
            version: "1.0.0",
            tools: [tool],
            resources: registry
        )

        #expect(server.name == "ToolsAndResourcesServer")
        #expect(server.version == "1.0.0")
        #expect(server.tools != nil)
        #expect(server.tools?.count == 1)
        #expect(server.tools?[0].name == "echo")
        #expect(server.resources != nil)
        #expect(server.resources?.resources.count == 1)
        #expect(server.resources?.resources[0].resource.name == "Documentation")
    }

    @Test("Register Resources With Server")
    func testRegisterResourcesWithServer() {
        // Create a server without resources
        let server = MCPServer.create(
            name: "EmptyServer",
            version: "1.0.0",
            tools: [any MCPToolProtocol]()
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

        // Register resources with the server
        let serverWithResources = server.registerResources(registry)

        #expect(serverWithResources.name == "EmptyServer")
        #expect(serverWithResources.version == "1.0.0")
        #expect(serverWithResources.resources != nil)
        #expect(serverWithResources.resources?.resources.count == 1)
        #expect(serverWithResources.resources?.resources[0].resource.name == "Documentation")
    }
}
