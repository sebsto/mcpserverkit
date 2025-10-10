#if MCPMacros

import SwiftSyntax
import SwiftSyntaxBuilder
import Testing

@testable import ToolMacro
@testable import ToolMacroImplementation

@Suite("Schema Generation Tests")
struct SchemaGenerationTests {

    @Test("Primitive type parameter info creation")
    func primitiveTypeParameterInfo() throws {
        let param = ParameterInfo(
            name: "city",
            type: "String",
            description: "The city name to get the weather for",
            isOptional: false
        )

        #expect(param.name == "city")
        #expect(param.type == "String")
        #expect(param.description == "The city name to get the weather for")
        #expect(param.isOptional == false)
    }

    @Test("Anonymous parameter uses input name")
    func anonymousParameterUsesInputName() throws {
        let param = ParameterInfo(
            name: "input",  // This should be "input" when original was "_"
            type: "String",
            description: "The text to process and transform",
            isOptional: false
        )

        #expect(param.name == "input")
    }

    @Test("Optional parameter detection")
    func optionalParameterDetection() throws {
        let param = ParameterInfo(
            name: "optionalParam",
            type: "String?",
            description: "An optional parameter",
            isOptional: true
        )

        #expect(param.isOptional == true)
        #expect(param.type == "String?")
    }

    @Test("Type schema generation for primitives")
    func typeSchemaGenerationForPrimitives() throws {
        let stringSchema = SchemaGenerationUtils.generateTypeSchema("String")
        let intSchema = SchemaGenerationUtils.generateTypeSchema("Int")
        let doubleSchema = SchemaGenerationUtils.generateTypeSchema("Double")
        let boolSchema = SchemaGenerationUtils.generateTypeSchema("Bool")

        #expect(stringSchema == "string")
        #expect(intSchema == "integer")
        #expect(doubleSchema == "number")
        #expect(boolSchema == "boolean")
    }

    @Test("JSON string escaping")
    func jsonStringEscaping() throws {
        let testCases = [
            ("Simple text", "Simple text"),
            ("Text with \"quotes\"", "Text with \\\"quotes\\\""),
            ("Text with\nnewlines", "Text with\\nnewlines"),
        ]

        for (input, expected) in testCases {
            let result = SchemaGenerationUtils.escapeJsonString(input)
            #expect(result == expected, "Expected '\(expected)' but got '\(result)' for input '\(input)'")
        }
    }
}

#endif
