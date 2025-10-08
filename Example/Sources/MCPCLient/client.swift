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

        let config = MCPServerConfiguration(from: URL("./json/mcp.json"))
        print(config)
    }
}
