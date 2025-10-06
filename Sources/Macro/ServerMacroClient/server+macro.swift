import MCPServerKit
import ServerMacro
import ToolMacro

// create a tool
@Tool(name: "Hello", description: "Say hello")
struct SayHello: ToolProtocol {
    /// Say Hello
    /// - Parameter input: the name of the person to say hello to
    func handle(input: String) async throws -> String { "Hello \(input)" }
}

// Create a server
@Server(
    name: "Say Hello Server",
    version: "1.0.0",
    description: "A simple server that says hello",
    tools: [SayHello()],
    type: .stdio
)
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
// or
//     try await server.startHttpServer
// }
