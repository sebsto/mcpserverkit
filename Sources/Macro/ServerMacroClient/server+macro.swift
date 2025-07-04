import MCPServerKit
import ToolMacro
import ServerMacro

@Tool(name: "Hello", description: "Say hello")
struct SayHello: MCPToolProtocol {
    /// Say Hello
    /// - Parameter input: the name of the person to say hello to
    func handler(input: String) async throws -> String { return "Hello \(input)" }
}

// Create a simple struct to hold our server
@Server(name: "Say Hello Server",
        version: "1.0.0",
        description: "A simple server that says hello",
        tools: [SayHello()],
        type: .stdio)
@main
struct MyServer {}

// the macro will automatically generate the code below
// to create and run the server
// public static func main() async throws {
//     let server = MCPServer(
//         name: "SayHelloServer",
//         version: "1.0.0",
//         tools: [ SayHello()]
//     )
//     try await server.startStdioServer()
// }

