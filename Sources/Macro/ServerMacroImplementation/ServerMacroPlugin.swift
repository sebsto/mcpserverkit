import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ServerMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ServerMacro.self
    ]
}
