import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main struct DocSchemaMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SchemaDefinitionMacro.self,
        DocSchemaMacro.self,
    ]
}
