#if MCPMacros

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main struct ToolMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SchemaDefinitionMacro.self,
        ToolMacro.self,
    ]
}

#endif