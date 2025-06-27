# MCPSwift

A high-level Swift framework for building Model Context Protocol (MCP) servers with a simplified API.

## Overview

MCPSwift provides `MCPServerKit`, a high-level and easy-to-use API built on top of [the official MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk). This framework simplifies the process of creating MCP-compatible tools and servers in Swift.

Key features:
- **Swift Macros**: Automatic tool schema generation and simplified server setup
- Simplified tool creation and registration
- Standardized error handling
- Streamlined server setup and communication
- Type-safe API for building MCP tools
- Support for heterogeneous tools with different input/output types
- Resource management for sharing files and data with LLMs
- Strongly-typed MIME type handling

The project includes examples demonstrating both macro-based and traditional approaches to implementing MCP servers.

## Quick Start with Macros (Recommended)

MCPSwift provides powerful Swift macros that dramatically reduce boilerplate code and automatically generate JSON schemas from your Swift types.

### Creating Tools with Macros

#### Basic Tool with Simple Types

```swift
import MCPServerKit
import ToolMacro

@Tool(name: "greet", description: "Greet someone by name")
struct GreetTool: MCPToolProtocol {
    /// Greet a person
    /// - Parameter input: The name of the person to greet
    func handler(input: String) async throws -> String {
        return "Hello, \(input)!"
    }
}
```

#### Advanced Tool with Custom Struct

```swift
import MCPServerKit
import ToolMacro

// Define input structure with automatic schema generation
@SchemaDefinition
struct CalculatorInput: Codable {
    /// First number for the calculation
    let a: Double
    
    /// Second number for the calculation  
    let b: Double
    
    /// Operation to perform (add, subtract, multiply, divide)
    /// Valid values: "add", "subtract", "multiply", "divide"
    let operation: String
}

@Tool(
    name: "calculator",
    description: "Performs basic arithmetic operations",
    schema: CalculatorInput.self
)
struct CalculatorTool: MCPToolProtocol {
    typealias Input = CalculatorInput
    typealias Output = Double
    
    /// Perform arithmetic calculation
    /// - Parameter input: The calculation parameters
    func handler(input: CalculatorInput) async throws -> Double {
        switch input.operation {
        case "add":
            return input.a + input.b
        case "subtract":
            return input.a - input.b
        case "multiply":
            return input.a * input.b
        case "divide":
            guard input.b != 0 else {
                throw MCPServerError.invalidParam("b", "Cannot divide by zero")
            }
            return input.a / input.b
        default:
            throw MCPServerError.invalidParam("operation", "Unknown operation: \(input.operation)")
        }
    }
}
```

### Creating Servers with Macros

#### Simple Server without Prompts

```swift
import MCPServerKit
import ServerMacro

@Server(
    name: "CalculatorServer",
    version: "1.0.0",
    description: "A server that performs calculations",
    tools: [
        GreetTool(),
        CalculatorTool()
    ],
    type: .stdio
)
@main
struct CalculatorServer {}

// The macro automatically generates:
// public static func main() async throws {
//     let server = MCPServer.create(
//         name: "CalculatorServer",
//         version: "1.0.0",
//         tools: [GreetTool(), CalculatorTool()]
//     )
//     try await server.startStdioServer()
// }
```

#### Server with Tools and Prompts

```swift
import MCPServerKit
import ServerMacro

// Create prompts for your server
let greetingPrompt = try! MCPPrompt.build { builder in
    builder.name = "friendly-greeting"
    builder.description = "Generate a friendly greeting"
    builder.text("Create a warm, friendly greeting for {name} in {language}")
    builder.parameter("name", description: "The person's name")
    builder.parameter("language", description: "The language for the greeting")
}

let calculationPrompt = try! MCPPrompt.build { builder in
    builder.name = "math-explanation"
    builder.description = "Explain a mathematical calculation"
    builder.text("Explain how to calculate {operation} of {a} and {b}")
    builder.parameter("operation", description: "The mathematical operation")
    builder.parameter("a", description: "First number")
    builder.parameter("b", description: "Second number")
}

@Server(
    name: "MultiToolServer",
    version: "1.0.0",
    description: "A server with tools and prompts",
    tools: [
        GreetTool(),
        CalculatorTool()
    ],
    prompts: [greetingPrompt, calculationPrompt],
    type: .stdio
)
@main
struct MultiToolServer {}

// The macro automatically generates:
// public static func main() async throws {
//     let server = MCPServer.create(
//         name: "MultiToolServer",
//         version: "1.0.0",
//         tools: [GreetTool(), CalculatorTool()],
//         prompts: [greetingPrompt, calculationPrompt]
//     )
//     try await server.startStdioServer()
// }
```

### Benefits of Using Macros

- **Automatic Schema Generation**: JSON schemas are generated from your Swift types and DocC comments
- **Type Safety**: Compile-time validation of your tool definitions
- **Reduced Boilerplate**: No need to manually write JSON schemas or server setup code
- **Documentation Integration**: DocC comments become parameter descriptions in the schema
- **Easy Server Setup**: Single macro generates complete server with main function

## MCPServerKit (Traditional Approach)

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
- Swift 6.2 or later
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
- **ServerMacro**: Swift macros for automatic server generation
- **ToolMacro**: Swift macros for automatic tool schema generation
- **ServerShared**: Shared types and protocols for macro system
- **Example**: Example implementations demonstrating both macro and traditional approaches
- **Tests**: Unit tests for the server components

## Using MCPServerKit (Traditional Approach)

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
- [Claude Desktop App](https://claude.ai/download)
- Other AI services that support the Model Context Protocol

To use your server, add this JSON configuration to your MCP Client:

```json
{
  "mcpServers": {
    "your-server": {
      "command": ".build/debug/YourServerExecutable",
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
