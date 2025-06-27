// Usage example
import MCPServerKit
import ServerMacro

// Create a simple struct to hold our server
@Server(type: .stdio)
struct MyServer {

    // create the server
    static let server = MCPServer(
        name: "OpenURLTool",
        version: "1.0.0",
        tools: []
    )
    // The macro will automatically generate a main() method
    // public static func main() async throws {
    //     try await server.startStdioServer()
    // }
}

