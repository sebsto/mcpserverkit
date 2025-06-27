import ServerShared

// Enum for different server types
public enum ServerType {
    case stdio
    // Future types can be added here
    // case tcp(port: Int)
    // case websocket(port: Int)
}

// Macro declaration
@attached(member, names: arbitrary)
public macro Server(
    name: String,
    version: String,
    description: String? = nil,
    tools: [any MCPToolProtocol],
    type: ServerType
) = #externalMacro(module: "ServerMacroImplementation", type: "ServerMacro")