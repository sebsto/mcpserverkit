# MCPSwift

A high-level Swift framework for building Model Context Protocol (MCP) servers with a simplified API.

## Overview

MCPSwift provides `MCPServerKit`, a high-level and easy-to-use API built on top of [the official MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk). This framework simplifies the process of creating MCP-compatible tools and servers in Swift.

Key features:
- Simplified tool creation and registration
- Standardized error handling
- Streamlined server setup and communication
- Type-safe API for building MCP tools
- Support for heterogeneous tools with different input/output types
- Resource management for sharing files and data with LLMs
- Strongly-typed MIME type handling

The project includes a weather tool example to demonstrate how to implement a functional MCP server using the framework.

## MCPServerKit

MCPServerKit is the core library that abstracts away the complexity of the MCP protocol, allowing developers to focus on building their tools rather than managing protocol details.

### Key Components

- **MCPToolProtocol**: Generic protocol defining the interface for MCP tools with associated Input and Output types
- **MCPTool**: A default abstraction for defining tools with schemas and handlers, supporting type-safe input and output
- **MCPServer**: Unified server implementation that supports tools, prompts, and resources
- **MCPResource**: Type-safe wrapper for MCP resources with support for text and binary data
- **MCPServerError**: Standardized error handling for MCP servers

### Benefits

- Reduces boilerplate code when implementing MCP tools and resources
- Provides a consistent pattern for tool development
- Handles the complexities of MCP communication
- Makes it easy to create and test new tools
- Allows tools with different input/output types to coexist in the same server
- Simplifies resource management for sharing files and data with LLMs

## Requirements

- macOS 15 or later
- Swift 6.1 or later
- Xcode 16 or later (recommended for development)

## Installation

Clone the repository:

```bash
git clone <repository-url>
cd MCPSwift
```

Build the project:

```bash
swift build
```

## Project Structure

- **MCPServerKit**: The core library for building MCP servers and tools
- **MCPExampleServer**: An example implementation that demonstrates how to use MCPServerKit
- **Tests**: Unit tests for the server components

## Using MCPServerKit

### Creating a Tool

```swift
import MCPServerKit

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
```

### Creating Resources

Resources allow you to share files, data, and other content with LLMs through the MCP protocol:

```swift
import MCPServerKit

// Create text resources with strongly-typed MIME types
let documentationResource = MCPResource.text(
    name: "API Documentation",
    uri: "docs://api-reference",
    content: "# API Reference\n\nThis document describes...",
    mimeType: .markdown
)

// Create binary resources
let logoResource = MCPResource.binary(
    name: "Logo",
    uri: "images://logo",
    data: imageData,
    mimeType: .png
)

// Create resources from files (automatically detects if text or binary)
let configResource = try MCPResource.file(
    name: "Configuration",
    uri: "config://settings",
    filePath: "/path/to/config.json"
)

// Create a resource registry
let registry = MCPResourceRegistry()
registry.add(documentationResource)
       .add(logoResource)
       .add(configResource)
```

### Setting Up a Server with Tools

```swift
import MCPServerKit

// Create the server with tools
let server = MCPServer.create(
    name: "MyMCPServer",
    version: "1.0.0",
    tools: myTool1, myTool2, myTool3
)

// Start the server
try await server.startStdioServer()
```

### Setting Up a Server with Resources

```swift
import MCPServerKit

// Create the server with resources
let server = MCPServer.create(
    name: "ResourceServer",
    version: "1.0.0",
    resources: registry
)

// Start the server
try await server.startStdioServer()
```

### Setting Up a Server with Both Tools and Resources

```swift
import MCPServerKit

// Create the server with both tools and resources
let server = MCPServer.create(
    name: "FullServer",
    version: "1.0.0",
    tools: [weatherTool, calculatorTool],
    resources: registry
)

// Start the server
try await server.startStdioServer()
```

### Adding Resources to an Existing Server

```swift
import MCPServerKit

// Create a server
let server = MCPServer.create(
    name: "MyServer",
    version: "1.0.0",
    tools: [myTool]
)

// Add resources to the server
let serverWithResources = server.registerResources(registry)

// Start the server
try await serverWithResources.startStdioServer()
```

## Example: Weather Tool with Resources

```swift
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

// Start the server
try await server.startStdioServer()
```

## Integrating with MCP Clients

Servers built with MCPServerKit can be used with any MCP-compatible client, including:

- [Amazon Q Developer CLI](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line-installing.html)
- [Claude Dekstop App](https://claude.ai/download)
- Other AI services that support the Model Context Protocol

To use the Weather example, add this JSON file to your MCP Client configuration:

```json
{
  "mcpServers": {
    "weather": {
      "command": ".build/debug/MCPWeatherServer",
      "args": []
    }
  }
}
```

## Dependencies

- [swift-sdk](https://github.com/modelcontextprotocol/swift-sdk) - The official Swift SDK for the Model Context Protocol

## License

This project is licensed under the terms included in the [MIT LICENSE](LICENSE) file.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
