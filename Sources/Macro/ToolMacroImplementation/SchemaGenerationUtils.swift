import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

/// Utility class for schema generation functionality shared between macros
public struct SchemaGenerationUtils {

    /// Extract documentation comments from leading trivia
    public static func extractDocCommentFromTrivia(_ trivia: Trivia) -> String? {
        var docLines: [String] = []

        for piece in trivia {
            switch piece {
            case .docLineComment(let text):
                let cleanText = String(text.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                docLines.append(cleanText)
            case .docBlockComment(let text):
                let cleanText =
                    text
                    .dropFirst(3)
                    .dropLast(2)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                docLines.append(cleanText)
            default:
                continue
            }
        }

        if docLines.isEmpty {
            return nil
        }

        return docLines.joined(separator: " ")
    }

    /// Generate JSON schema type from Swift type
    public static func generateTypeSchema(_ type: String) -> String {
        switch type.lowercased() {
        case "string":
            return "string"
        case "int", "integer", "int32", "int64":
            return "integer"
        case "double", "float", "number":
            return "number"
        case "bool", "boolean":
            return "boolean"
        default:
            return "object"
        }
    }

    /// Extract access level from declaration
    public static func extractAccessLevel(from declaration: some DeclGroupSyntax) -> String? {
        declaration.modifiers.first { modifier in
            ["public", "internal", "package", "fileprivate", "private"].contains(modifier.name.text)
        }?
        .name.text
    }

    /// Generate schema JSON from a struct declaration
    public static func generateSchemaJson(from structDecl: StructDeclSyntax, description: String? = nil) -> String {
        var properties: [String] = []
        var required: [String] = []

        for member in structDecl.memberBlock.members {
            if let variableDecl = member.decl.as(VariableDeclSyntax.self) {
                let docComment = extractDocCommentFromTrivia(variableDecl.leadingTrivia)

                for binding in variableDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                        let typeAnnotation = binding.typeAnnotation
                    {
                        let propertyName = identifier.identifier.text
                        let propertyType = typeAnnotation.type.trimmed.description
                        let isOptional = propertyType.hasSuffix("?")

                        let cleanType = isOptional ? String(propertyType.dropLast()) : propertyType
                        let jsonType = generateTypeSchema(cleanType)

                        // Add description to property schema if available
                        if let propertyDescription = docComment {
                            let escapedDescription = escapeJsonString(propertyDescription)
                            properties.append(
                                "\"\(propertyName)\": { \"type\": \"\(jsonType)\", \"description\": \"\(escapedDescription)\" }"
                            )
                        } else {
                            properties.append("\"\(propertyName)\": { \"type\": \"\(jsonType)\" }")
                        }

                        if !isOptional {
                            required.append("\"\(propertyName)\"")
                        }
                    }
                }
            }
        }

        let propertiesJson = properties.joined(separator: ", ")
        let requiredJson = required.joined(separator: ", ")

        var schema = "{ \"type\": \"object\", \"properties\": { \(propertiesJson) }"

        if let description = description {
            let escapedDescription = escapeJsonString(description)
            schema =
                "{ \"type\": \"object\", \"description\": \"\(escapedDescription)\", \"properties\": { \(propertiesJson) }"
        }

        if !required.isEmpty {
            schema += ", \"required\": [\(requiredJson)]"
        }

        schema += " }"

        return schema
    }

    /// Escape special characters in strings for JSON
    public static func escapeJsonString(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")  // Escape backslashes first
            .replacingOccurrences(of: "\"", with: "\\\"")  // Escape quotes
            .replacingOccurrences(of: "\n", with: "\\n")  // Escape newlines
            .replacingOccurrences(of: "\r", with: "\\r")  // Escape carriage returns
            .replacingOccurrences(of: "\t", with: "\\t")  // Escape tabs
        // Escape tabs
    }

    /// Clean and escape JSON for string literals
    public static func cleanAndEscapeJson(_ json: String) -> String {
        let cleanedJson =
            json
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        return cleanedJson.replacingOccurrences(of: "\"", with: "\\\"")
    }

    /// Find a nested type within a struct declaration
    public static func findNestedType(in structDecl: StructDeclSyntax, typeName: String) -> StructDeclSyntax? {
        for member in structDecl.memberBlock.members {
            if let nestedStruct = member.decl.as(StructDeclSyntax.self),
                nestedStruct.name.text == typeName
            {
                return nestedStruct
            }
        }
        return nil
    }
}
