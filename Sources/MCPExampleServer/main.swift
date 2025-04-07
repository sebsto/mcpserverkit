import MCPServerKit

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

// Create the server with multiple tools of different types
let server = MCPServer.create(
    name: "MultiToolServer",
    version: "1.0.0",
    tools: [
        myWeatherTool.asJSONTool(),  // String input, String output
        calculatorTool.asJSONTool(),  // CalculatorInput input, Double output
    ]
)

// Start the server
try await server.startStdioServer()
