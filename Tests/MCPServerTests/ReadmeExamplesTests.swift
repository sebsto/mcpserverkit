import MCP
import Testing

@testable import MCPServerKit

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// This test suite verifies that all code examples in the README.md file actually compile
@Suite("README Examples Tests")
struct ReadmeExamplesTests {

    @Test("Creating a Tool Example")
    func testCreatingToolExample() {
        // Define your tool's schema
        let myToolSchema = """
            {
                "type": "object",
                "properties": {
                  "parameter_name": {
                    "description": "Description of the parameter",
                    "type": "string"
                  }
                },
                "required": [
                  "parameter_name"
                ]
            }
            """

        // Create your tool with a handler function and converter
        let myTool = MCPTool<String, String>(
            name: "tool_name",
            description: "Description of what your tool does",
            inputSchema: myToolSchema,
            body: { (input: String) async throws -> String in
                // Process the input and return a result
                "Processed: \(input)"
            }
        )

        // Verify the tool was created correctly
        #expect(myTool.toolName == "tool_name")
        #expect(myTool.toolDescription == "Description of what your tool does")
    }

    @Test("Creating Resources Example")
    func testCreatingResourcesExample() {
        // Create text resources with strongly-typed MIME types
        let documentationResource = MCPResource.text(
            name: "API Documentation",
            uri: "docs://api-reference",
            content: "# API Reference\n\nThis document describes...",
            mimeType: .markdown
        )

        // Create binary resources
        let imageData = Data([0x01, 0x02, 0x03, 0x04])
        let logoResource = MCPResource.binary(
            name: "Logo",
            uri: "images://logo",
            data: imageData,
            mimeType: .png
        )

        // Create a resource registry
        let registry = MCPResourceRegistry()
        registry.add(documentationResource)
            .add(logoResource)

        // Verify resources were added correctly
        #expect(registry.resources.count == 2)
        #expect(registry.resources[0].resource.name == "API Documentation")
        #expect(registry.resources[1].resource.name == "Logo")
    }

    @Test("Setting Up a Server with Tools Example")
    func testSettingUpServerWithToolsExample() async throws {
        // Create tools
        let myTool1 = MCPTool<String, String>(
            name: "tool1",
            description: "Tool 1",
            inputSchema: "{}",
            body: { _ in "" }
        )

        let myTool2 = MCPTool<String, String>(
            name: "tool2",
            description: "Tool 2",
            inputSchema: "{}",
            body: { _ in "" }
        )

        let myTool3 = MCPTool<String, String>(
            name: "tool3",
            description: "Tool 3",
            inputSchema: "{}",
            body: { _ in "" }
        )

        // Create the server with tools
        try await MCPServer.withMCPServer(
            name: "MyMCPServer",
            version: "1.0.0",
            transport: .stdio,
            tools: [myTool1, myTool2, myTool3]
        ) { server in
            // Verify server was created correctly
            #expect(server.name == "MyMCPServer")
            #expect(server.version == "1.0.0")
            #expect(server.tools?.count == 3)
        }
    }

    @Test("Setting Up a Server with Resources Example")
    func testSettingUpServerWithResourcesExample() async throws {
        // Create resources
        let resource = MCPResource.text(
            name: "Documentation",
            uri: "docs://api",
            content: "# API Documentation",
            mimeType: .markdown
        )

        // Create registry
        let registry = MCPResourceRegistry()
        registry.add(resource)

        // Create the server with resources
        try await MCPServer.withMCPServer(
            name: "ResourceServer",
            version: "1.0.0",
            transport: .stdio,
            resources: registry
        ) { server in
            // Verify server was created correctly
            #expect(server.name == "ResourceServer")
            #expect(server.version == "1.0.0")
            #expect(server.resources.resources.count == 1)
        }
    }

    @Test("Setting Up a Server with Both Tools and Resources Example")
    func testSettingUpServerWithBothToolsAndResourcesExample() async throws {
        // Create tools
        let weatherTool = MCPTool<String, String>(
            name: "weather",
            description: "Weather tool",
            inputSchema: "{}",
            body: { _ in "" }
        )

        let calculatorTool = MCPTool<String, String>(
            name: "calculator",
            description: "Calculator tool",
            inputSchema: "{}",
            body: { _ in "" }
        )

        // Create resources
        let resource = MCPResource.text(
            name: "Documentation",
            uri: "docs://api",
            content: "# API Documentation",
            mimeType: .markdown
        )

        // Create registry
        let registry = MCPResourceRegistry()
        registry.add(resource)

        // Create the server with both tools and resources
        try await MCPServer.withMCPServer(
            name: "FullServer",
            version: "1.0.0",
            transport: .stdio,
            tools: [weatherTool, calculatorTool],
            resources: registry
        ) { server in
            // Verify server was created correctly
            #expect(server.name == "FullServer")
            #expect(server.version == "1.0.0")
            #expect(server.tools?.count == 2)
            #expect(server.resources.resources.count == 1)
        }
    }

    @Test("Adding Resources to an Existing Server Example")
    func testAddingResourcesToExistingServerExample() async throws {
        // Create a tool
        let myTool = MCPTool<String, String>(
            name: "tool",
            description: "Tool",
            inputSchema: "{}",
            body: { _ in "" }
        )

        // Create a server
        try await MCPServer.withMCPServer(
            name: "MyServer",
            version: "1.0.0",
            transport: .stdio,
            tools: [myTool]
        ) { server in

            // Create resources
            let resource = MCPResource.text(
                name: "Documentation",
                uri: "docs://api",
                content: "# API Documentation",
                mimeType: .markdown
            )

            // Create registry
            let registry = MCPResourceRegistry(resources: [resource])

            // Add resources to the server
            await server.registerResources(resources: registry)

            // Verify server was updated correctly
            #expect(server.name == "MyServer")
            #expect(server.version == "1.0.0")
            #expect(server.tools?.count == 1)
            #expect(server.resources.resources.count == 1)
        }
    }

    @Test("Weather Tool with Resources Example")
    func testWeatherToolWithResourcesExample() async throws {
        // Weather tool
        let weatherTool = MCPTool<String, String>(
            name: "weather",
            description: "Get weather information for a city",
            inputSchema: """
                {
                    "type": "object",
                    "properties": {
                        "city": {
                            "type": "string",
                            "description": "The city to get weather for"
                        }
                    },
                    "required": ["city"]
                }
                """,
            body: { city in
                // Implementation would fetch weather data
                "Weather for \(city): Sunny, 72°F"
            }
        )

        // Weather resources
        let registry = MCPResourceRegistry()
        registry.add(
            MCPResource.text(
                name: "Weather API Documentation",
                uri: "docs://weather-api",
                content: "# Weather API\n\nThis API provides weather information...",
                mimeType: .markdown
            )
        )

        // Create server with both tool and resources
        try await MCPServer.withMCPServer(
            name: "WeatherServer",
            version: "1.0.0",
            transport: .stdio,
            tools: [weatherTool],
            resources: registry
        ) { server in

            // Verify server was created correctly
            #expect(server.name == "WeatherServer")
            #expect(server.version == "1.0.0")
            #expect(server.tools?.count == 1)
            #expect(server.tools?[0].toolName == "weather")
            #expect(server.resources.resources.count == 1)
            #expect(server.resources.resources[0].resource.name == "Weather API Documentation")
        }
    }
}
