#if MCPMacros

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Testing

@testable import ToolMacro
@testable import ToolMacroImplementation

@Suite("SchemaGenerationUtils Tests")
struct SchemaGenerationUtilsTests {

    @Test("Extract doc comment from trivia")
    func testExtractDocCommentFromTrivia() {
        // Create trivia with doc comments
        let trivia = Trivia(pieces: [
            .docLineComment("/// This is a test comment"),
            .newlines(1),
            .docLineComment("/// Another line"),
        ])

        // Extract the doc comment
        let docComment = SchemaGenerationUtils.extractDocCommentFromTrivia(trivia)

        // Verify the result
        #expect(docComment == "This is a test comment Another line")
    }

    @Test("Generate schema type from Swift type")
    func testGenerateTypeSchema() {
        // Test various Swift types
        #expect(SchemaGenerationUtils.generateTypeSchema("String") == "string")
        #expect(SchemaGenerationUtils.generateTypeSchema("Int") == "integer")
        #expect(SchemaGenerationUtils.generateTypeSchema("Double") == "number")
        #expect(SchemaGenerationUtils.generateTypeSchema("Bool") == "boolean")
        #expect(SchemaGenerationUtils.generateTypeSchema("CustomType") == "object")
    }

    @Test("Clean and escape JSON")
    func testCleanAndEscapeJson() {
        // Create a JSON string with newlines and spaces
        let json = """
            {
              "type": "object",
              "properties": {
                "name": { "type": "string" }
              }
            }
            """

        // Clean and escape the JSON
        let cleanedJson = SchemaGenerationUtils.cleanAndEscapeJson(json)

        // The actual implementation might have different whitespace handling
        // So we'll compare without whitespace
        let normalizedCleaned = cleanedJson.replacingOccurrences(of: " ", with: "")
        let normalizedExpected =
            "{\\\"type\\\":\\\"object\\\",\\\"properties\\\":{\\\"name\\\":{\\\"type\\\":\\\"string\\\"}}}"
            .replacingOccurrences(of: " ", with: "")

        // Verify the result
        #expect(normalizedCleaned == normalizedExpected)
    }

    @Test("Non-optional fields appear in required section of schema")
    func testNonOptionalFieldsInRequiredSection() async throws {
        // Create a struct declaration directly using SwiftSyntaxBuilder
        let structDecl = try StructDeclSyntax("struct TestStruct {}") {
            DeclSyntax("var requiredField: String")
            DeclSyntax("var optionalField: Int?")
            DeclSyntax("var anotherRequired: Bool")
        }

        // Generate schema JSON from the struct
        let schemaJson = SchemaGenerationUtils.generateSchemaJson(from: structDecl)

        // Verify that required fields are in the required section
        let requiredFieldsInCorrectOrder = schemaJson.contains("\"required\": [\"requiredField\", \"anotherRequired\"]")
        let requiredFieldsInReverseOrder = schemaJson.contains("\"required\": [\"anotherRequired\", \"requiredField\"]")

        #expect(
            requiredFieldsInCorrectOrder || requiredFieldsInReverseOrder,
            "Non-optional fields should appear in the required section"
        )

        // Verify that optional field is not in the required section
        #expect(
            !schemaJson.contains("\"required\": [\"optionalField\"]"),
            "Optional fields should not appear in the required section"
        )

        // Print the generated schema for debugging
        // print("Generated schema: \(schemaJson)")
    }
}

#endif
