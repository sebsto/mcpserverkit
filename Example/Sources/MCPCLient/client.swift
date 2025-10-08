import AgentKit
import Logging

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@main
struct Test {
    static func main() async throws {

        var logger = Logger(label: "MCPClient")
        logger.logLevel = .trace

        let configFile = "./json/mcp.json"
        let url = URL(fileURLWithPath: configFile)

        let config = try MCPServerConfiguration(from: url)

        // experiment with stdio server
        let serverName = "MCPExample-stdio"
        guard let serverConfig = config[serverName] else {
            throw MCPToolError.serverNotFound(name: serverName)
        }
        let client = try await MCPClient(with: serverConfig, name: serverName, logger: logger)
        print(try await client.invokeTool(name: "weather", arguments: ["input": "lille"], logger: logger))
    }
}
