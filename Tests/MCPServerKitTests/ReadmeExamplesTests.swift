import XCTest
import Testing
import MCP
@testable import MCPServerKit

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
            converter: { params in
                // Convert the input parameters to the expected type
                try MCPTool<String, String>.extractParameter(params, name: "parameter_name")
            },
            body: { (input: String) async throws -> String in
                // Process the input and return a result
                return "Processed: \(input)"
            }
        )
        
        // Verify the tool was created correctly
        #expect(myTool.name == "tool_name")
        #expect(myTool.description == "Description of what your tool does")
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
    func testSettingUpServerWithToolsExample() {
        // Create tools
        let myTool1 = MCPTool<String, String>(
            name: "tool1",
            description: "Tool 1",
            inputSchema: "{}",
            converter: { _ in return "" },
            body: { _ in return "" }
        )
        
        let myTool2 = MCPTool<String, String>(
            name: "tool2",
            description: "Tool 2",
            inputSchema: "{}",
            converter: { _ in return "" },
            body: { _ in return "" }
        )
        
        let myTool3 = MCPTool<String, String>(
            name: "tool3",
            description: "Tool 3",
            inputSchema: "{}",
            converter: { _ in return "" },
            body: { _ in return "" }
        )

        // Create the server with tools
        let server = MCPServer.create(
            name: "MyMCPServer",
            version: "1.0.0",
            tools: myTool1, myTool2, myTool3
        )
        
        // Verify server was created correctly
        #expect(server.name == "MyMCPServer")
        #expect(server.version == "1.0.0")
        #expect(server.tools?.count == 3)
    }
    
    @Test("Setting Up a Server with Resources Example")
    func testSettingUpServerWithResourcesExample() {
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
        let server = MCPServer.create(
            name: "ResourceServer",
            version: "1.0.0",
            resources: registry
        )
        
        // Verify server was created correctly
        #expect(server.name == "ResourceServer")
        #expect(server.version == "1.0.0")
        #expect(server.resources?.resources.count == 1)
    }
    
    @Test("Setting Up a Server with Both Tools and Resources Example")
    func testSettingUpServerWithBothToolsAndResourcesExample() {
        // Create tools
        let weatherTool = MCPTool<String, String>(
            name: "weather",
            description: "Weather tool",
            inputSchema: "{}",
            converter: { _ in return "" },
            body: { _ in return "" }
        )
        
        let calculatorTool = MCPTool<String, String>(
            name: "calculator",
            description: "Calculator tool",
            inputSchema: "{}",
            converter: { _ in return "" },
            body: { _ in return "" }
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
        let server = MCPServer.create(
            name: "FullServer",
            version: "1.0.0",
            tools: [weatherTool, calculatorTool],
            resources: registry
        )
        
        // Verify server was created correctly
        #expect(server.name == "FullServer")
        #expect(server.version == "1.0.0")
        #expect(server.tools?.count == 2)
        #expect(server.resources?.resources.count == 1)
    }
    
    @Test("Adding Resources to an Existing Server Example")
    func testAddingResourcesToExistingServerExample() {
        // Create a tool
        let myTool = MCPTool<String, String>(
            name: "tool",
            description: "Tool",
            inputSchema: "{}",
            converter: { _ in return "" },
            body: { _ in return "" }
        )
        
        // Create a server
        let server = MCPServer.create(
            name: "MyServer",
            version: "1.0.0",
            tools: [myTool]
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

        // Add resources to the server
        let serverWithResources = server.registerResources(registry)
        
        // Verify server was updated correctly
        #expect(serverWithResources.name == "MyServer")
        #expect(serverWithResources.version == "1.0.0")
        #expect(serverWithResources.tools?.count == 1)
        #expect(serverWithResources.resources?.resources.count == 1)
    }
    
    @Test("Weather Tool with Resources Example")
    func testWeatherToolWithResourcesExample() {
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
            converter: { params in
                try MCPTool<String, String>.extractParameter(params, name: "city")
            },
            body: { city in
                // Implementation would fetch weather data
                return "Weather for \(city): Sunny, 72°F"
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
        let server = MCPServer.create(
            name: "WeatherServer",
            version: "1.0.0",
            tools: [weatherTool],
            resources: registry
        )
        
        // Verify server was created correctly
        #expect(server.name == "WeatherServer")
        #expect(server.version == "1.0.0")
        #expect(server.tools?.count == 1)
        #expect(server.tools?[0].name == "weather")
        #expect(server.resources?.resources.count == 1)
        #expect(server.resources?.resources[0].resource.name == "Weather API Documentation")
    }
}
