import Testing
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation
@testable import ToolMacro
@testable import ToolMacroImplementation

@Suite("SchemaDefinitionMacro Tests")
struct SchemaDefinitionMacroTests {
    
    @Test("Schema generation for struct")
    func testSchemaGeneration() throws {
        // Create a simple struct declaration
        let structDecl = try StructDeclSyntax("struct TestStruct { let property: String }")
        
        // Generate schema JSON
        let schemaJson = SchemaGenerationUtils.generateSchemaJson(from: structDecl)
        
        // Verify the schema contains the property
        #expect(schemaJson.contains("property"))
        #expect(schemaJson.contains("string"))
    }
    
    @Test("Schema generation with description")
    func testSchemaGenerationWithDescription() throws {
        // Create a simple struct declaration
        let structDecl = try StructDeclSyntax("struct TestStruct { let property: String }")
        
        // Generate schema JSON with description
        let schemaJson = SchemaGenerationUtils.generateSchemaJson(from: structDecl, description: "Test description")
        
        // Verify the schema contains the description
        #expect(schemaJson.contains("Test description"))
    }
    
    @Test("Schema generation with quotes in description produces invalid JSON")
    func testSchemaGenerationWithQuotesInDescription() throws {
        // Create a struct with a description containing quotes
        let structDecl = try StructDeclSyntax("struct TestStruct { let property: String }")
        
        // Generate schema JSON with description containing quotes
        let schemaJson = SchemaGenerationUtils.generateSchemaJson(from: structDecl, description: "Test \"quoted\" description")
        
        // Try to parse the JSON to verify it's valid
        let jsonData = schemaJson.data(using: .utf8)!
        
        // This should not throw if JSON is valid
        #expect(throws: Never.self) {
            try JSONSerialization.jsonObject(with: jsonData, options: [])
        }
        
        // Verify the description is properly escaped
        #expect(schemaJson.contains("Test \\\"quoted\\\" description"))
    }
    
    @Test("Schema generation with quotes in property description")
    func testSchemaGenerationWithQuotesInPropertyDescription() throws {
        // Create a struct with a property that has a description containing quotes
        let structDecl = try StructDeclSyntax("""
        struct TestStruct { 
            /// This is a "quoted" property description
            let property: String 
        }
        """)
        
        // Generate schema JSON
        let schemaJson = SchemaGenerationUtils.generateSchemaJson(from: structDecl)
        
        // Try to parse the JSON to verify it's valid
        let jsonData = schemaJson.data(using: .utf8)!
        
        // This should not throw if JSON is valid
        #expect(throws: Never.self) {
            try JSONSerialization.jsonObject(with: jsonData, options: [])
        }
        
        // Verify the property description is properly escaped
        #expect(schemaJson.contains("This is a \\\"quoted\\\" property description"))
    }
    
    @Test("Schema generation escaping utility test")
    func testEscapeJsonString() throws {
        // Test the JSON string escaping utility function
        let testCases = [
            ("Simple text", "Simple text"),
            ("Text with \"quotes\"", "Text with \\\"quotes\\\""),
            ("Text with\nnewlines", "Text with\\nnewlines"),
            ("Mixed \"quotes\" and\ttabs", "Mixed \\\"quotes\\\" and\\ttabs")
        ]
        
        for (input, expected) in testCases {
            let result = SchemaGenerationUtils.escapeJsonString(input)
            #expect(result == expected, "Expected '\(expected)' but got '\(result)' for input '\(input)'")
        }
    }
}
