import Testing
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
@testable import DocSchemaMacro
@testable import DocSchemaMacroImplementation

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
}
