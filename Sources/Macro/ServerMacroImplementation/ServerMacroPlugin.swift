#if MCPMacros

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ServerMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ServerMacro.self
    ]
}

#else 

@main
struct MacrosDisabled{
    public static func main() {
        fatalError("Enable the MCPMacros to use the @Server macro")
    }
}

#endif