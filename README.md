# MCPSwift

A high-level Swift framework for building Model Context Protocol (MCP) servers with a simplified API.

## Overview

MCPSwift provides `MCPServerKit`, a high-level and easy-to-use API built on top of [the official MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk). This framework simplifies the process of creating MCP-compatible tools and servers in Swift.

Key features:
- Simplified tool creation and registration
- Standardized error handling
- Streamlined server setup and communication
- Type-safe API for building MCP tools

The project includes a weather tool example to demonstrate how to implement a functional MCP server using the framework.

## MCPServerKit

MCPServerKit is the core library that abstracts away the complexity of the MCP protocol, allowing developers to focus on building their tools rather than managing protocol details.

### Key Components

- **MCPToolProtocol**: Generic protocol defining the interface for MCP tools with associated Input and Output types
- **MCPTool**: A default abstraction for defining tools with schemas and handlers, supporting type-safe input and output
- **MCPServer**: Manages server lifecycle and communication
- **MCPServerError**: Standardized error handling for MCP servers

### Benefits

- Reduces boilerplate code when implementing MCP tools
- Provides a consistent pattern for tool development
- Handles the complexities of MCP communication
- Makes it easy to create and test new tools

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
- **MCPWeatherServer**: An example implementation that demonstrates how to use MCPServerKit
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
        try await MCPTool<String, String>.extractStringParameter(params, name: "parameter_name")
    },
    body: { (input: String) async throws -> String in
        // Process the input and return a result
        return "Processed: \(input)"
    }
)
```

### Setting Up a Server

```swift
import MCPServerKit

// Start the server with your tools
try await MCPServer.startStdioServer(
    name: "MyMCPServer",
    version: "1.0.0",
    tools: [myTool]
) 
```

## Example: Weather Tool

The included weather tool demonstrates a practical implementation using MCPServerKit:

```swift
let myWeatherTool = MCPTool<String, String>(
    name: "weather",
    description: "Returns weather data for a specified city",
    inputSchema: weatherSchema,
    converter: { params in 
        try await MCPTool<String, String>.extractStringParameter(params, name: "city") 
    },
    body: { (city: String) async throws -> String in
        // Fetch weather data for the city
        let weatherURL = "http://wttr.in/\(city)?format=j1"
        let url = URL(string: weatherURL)
        guard let url else {
            throw MCPServerError.invalidParam("city", "\(city)")
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        
        return String(data: data, encoding: .utf8) ?? "Unable to decode response"
    }
)
```

To run the example:

```bash
swift run MCPWeatherServer
```

## Integrating with MCP Clients

Servers built with MCPServerKit can be used with any MCP-compatible client, including:

- [Amazon Q Developer CLI](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line-installing.html)
- [Claude Dekstop App](https://claude.ai/download)
- Other AI services that support the Model Context Protocol

To use the Weather example, add this JSON file to tour MCP CLient configuration 

```
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
