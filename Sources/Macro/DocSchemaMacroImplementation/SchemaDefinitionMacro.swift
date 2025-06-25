import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation
import DocSchemaShared

/// A macro that generates an OpenAPI schema for a type
public struct SchemaDefinitionMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            return []
        }
        
        let schemaJson = SchemaGenerationUtils.generateSchemaJson(from: structDecl)
        let accessLevel = SchemaGenerationUtils.extractAccessLevel(from: structDecl)
        let accessModifier = accessLevel.map { "\($0) " } ?? ""
        
        let escapedSchemaJson = SchemaGenerationUtils.cleanAndEscapeJson(schemaJson)
        
        let propertyCode = "\(accessModifier) static var schema: String { return \"\(escapedSchemaJson)\" }"
        let schemaProperty: DeclSyntax = "\(raw: propertyCode)"
        
        return [schemaProperty]
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let schemaExtension = try ExtensionDeclSyntax("extension \(type): Schema {}")
        return [schemaExtension]
    }
}
