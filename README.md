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

The project includes a weather tool example to demonstrate how to implement a functional MCP server using the framework.

## MCPServerKit

MCPServerKit is the core library that abstracts away the complexity of the MCP protocol, allowing developers to focus on building their tools rather than managing protocol details.

### Key Components

- **MCPToolProtocol**: Generic protocol defining the interface for MCP tools with associated Input and Output types
- **MCPTool**: A default abstraction for defining tools with schemas and handlers, supporting type-safe input and output
- **MCPServer**: Unified server implementation that supports both homogeneous and heterogeneous tools
- **MCPServerError**: Standardized error handling for MCP servers
- **JSONBasedMCPTool**: Protocol for tools that work with JSON-based input/output

### Benefits

- Reduces boilerplate code when implementing MCP tools
- Provides a consistent pattern for tool development
- Handles the complexities of MCP communication
- Makes it easy to create and test new tools
- Allows tools with different input/output types to coexist in the same server

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
        try await MCPTool<String, String>.extractParameter(params, name: "parameter_name")
    },
    body: { (input: String) async throws -> String in
        // Process the input and return a result
        return "Processed: \(input)"
    }
)
```

### Setting Up a Server with Homogeneous Tools

If all your tools have the same input and output types, you can use the homogeneous tools factory method:

```swift
import MCPServerKit

// create the server
let server = MCPServer.create(
    name: "MyMCPServer",
    version: "1.0.0",
    tools: myTool1, myTool2, myTool3  // all tools have same Input/Output types
)
// start the server
try await server.startStdioServer()
```

### Setting Up a Server with Heterogeneous Tools

If your tools have different input and output types, use the heterogeneous tools factory method:

```swift
import MCPServerKit

// Create the server with multiple tools of different types
let server = MCPServer.create(
    name: "MultiToolServer",
    version: "1.0.0",
    tools: [
        weatherTool.asJSONTool(),  // String input, String output
        calculatorTool.asJSONTool() // Different input/output types
    ]
)

// Start the server
try await server.startStdioServer()
```

## Example: Weather and Calculator Tools

The included example demonstrates a practical implementation using MCPServerKit with multiple tool types:

```swift
// Weather tool (String input, String output)
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
        try await MCPTool<String, String>.extractParameter(params, name: "city")
    },
    body: { city in
        // Implementation would fetch weather data
        return "Weather for \(city): Sunny, 72°F"
    }
)

// Calculator tool (CalculatorInput input, Double output)
struct CalculatorInput: Codable {
    let operation: String
    let numbers: [Double]
}

let calculatorTool = MCPTool<CalculatorInput, Double>(
    name: "calculator",
    description: "Perform mathematical operations",
    inputSchema: """
    {
        "type": "object",
        "properties": {
            "operation": {
                "type": "string",
                "enum": ["add", "subtract", "multiply", "divide"]
            },
            "numbers": {
                "type": "array",
                "items": {
                    "type": "number"
                }
            }
        },
        "required": ["operation", "numbers"]
    }
    """,
    converter: { params in
        try await MCPTool<CalculatorInput, Double>.extractParameter(params, name: "input")
    },
    body: { input in
        switch input.operation {
        case "add":
            return input.numbers.reduce(0, +)
        case "subtract":
            return input.numbers.dropFirst().reduce(input.numbers[0], -)
        case "multiply":
            return input.numbers.reduce(1, *)
        case "divide":
            return input.numbers.dropFirst().reduce(input.numbers[0], /)
        default:
            throw MCPServerError.invalidParam("operation", input.operation)
        }
    }
)
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
