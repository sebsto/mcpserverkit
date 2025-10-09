#if MCPMacros

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ToolMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SchemaDefinitionMacro.self,
        ToolMacro.self,
    ]
}

#else 

@main struct MacrosDisabled {
    public static func main() {
        fatalError("Enable the MCPMacros to use the @Tool macro")
    }
}

#endif