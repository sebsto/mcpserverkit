// MCPServerMacroImplementation.swift - New file for macro implementation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftCompilerPlugin

public struct ServerMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Ensure this is applied to a struct
        guard let _ = declaration.as(StructDeclSyntax.self) else {
            throw MacroError.invalidDeclaration
        }
        
        // Extract macro arguments
        guard let arguments = node.arguments,
              case let .argumentList(argumentList) = arguments else {
            throw MacroError.invalidArguments
        }
        
        var serverName: String = ""
        var serverVersion: String = ""
        // var serverDescription: String? = ""
        var toolsArray: String = "[]"
        var promptsArray: String = "[]"
        var serverType: String = "stdio"
        
        // Parse the arguments
        for argument in argumentList {
            guard let label = argument.label?.text else { continue }
            
            switch label {
            case "name":
                if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
                   let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                    serverName = segment.content.text
                }
            case "version":
                if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
                   let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                    serverVersion = segment.content.text
                }
            // Uncomment if you want to support description in the future
            // case "description":
            //     if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
            //        let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
            //         serverDescription = segment.content.text
            //     }
            case "tools":
                if let arrayExpr = argument.expression.as(ArrayExprSyntax.self) {
                    let elements = arrayExpr.elements.map { element in
                        element.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    toolsArray = "[\(elements.joined(separator: ", "))]"
                }
            case "prompts":
                if let arrayExpr = argument.expression.as(ArrayExprSyntax.self) {
                    let elements = arrayExpr.elements.map { element in
                        element.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    promptsArray = "[\(elements.joined(separator: ", "))]"
                }
            case "type":
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    serverType = memberAccess.declName.baseName.text
                }
            default:
                break
            }
        }
        
        // Generate the appropriate startup code based on server type
        let startupCode: String
        switch serverType {
        case "stdio":
            startupCode = "try await server.startStdioServer()"
        default:
            startupCode = "try await server.startStdioServer()"
        }
        
        // Create a static main method that creates and starts the server
        let mainMethod: DeclSyntax = """
        public static func main() async throws {
            // Auto-generated by @Server macro
            let server = MCPServer.create(
                name: "\(raw: serverName)",
                version: "\(raw: serverVersion)",
                tools: \(raw: toolsArray),
                prompts: \(raw: promptsArray)
            )
            \(raw: startupCode)
        }
        """
        
        return [mainMethod]
    }
}

enum MacroError: Error, CustomStringConvertible {
    case invalidArguments
    case invalidDeclaration
    
    var description: String {
        switch self {
        case .invalidArguments:
            return "Invalid macro arguments"
        case .invalidDeclaration:
            return "Macro can only be applied to struct declarations"
        }
    }
}