#if MCPMacros

import MCPShared

// Macro declaration
@attached(member, names: arbitrary)
public macro Server(
    name: String,
    version: String,
    description: String? = nil,
    tools: [any ToolProtocol],
    prompts: [Any] = [],
    type: MCPTransport
) = #externalMacro(module: "ServerMacroImplementation", type: "ServerMacro")

#endif