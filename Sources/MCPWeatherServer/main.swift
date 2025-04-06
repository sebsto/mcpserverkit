import MCPServerKit

#if canImport(FoundationEssentials)
import FoundatioNEssentials
#else
import Foundation
#endif

// start the server
try await MCPServer.startStdioServer(
    name: "MyMCPServer",
    version: "1.0.0",
    tools: [myWeatherTool]
)
