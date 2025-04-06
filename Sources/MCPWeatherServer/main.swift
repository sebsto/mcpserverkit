import MCPServerKit

#if canImport(FoundationEssentials)
import FoundatioNEssentials
#else
import Foundation
#endif

// create the server
let server = MCPServer(
    name: "MyMCPServer",
    version: "1.0.0",
    tools: [myWeatherTool]
)
// start the server
try await server.startStdioServer()
