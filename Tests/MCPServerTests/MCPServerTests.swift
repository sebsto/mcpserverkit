import Foundation
import MCP
import MCPServerKit
import Testing

@Suite("MCPServerTests")
struct MCPServerTests {

    // Mock tool for testing
    struct MockInput: Codable, Equatable {
        let value: String
    }

    struct MockOutput: Codable, Equatable {
        let result: String
    }

    // Test that a tool can be created correctly
    @Test("Test MCPTool initialization")
    func testMCPToolInitialization() throws {
        let name = "mockTool"
        let description = "A mock tool for testing"
        let inputSchema = """
            {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "string"
                    }
                },
                "required": ["value"]
            }
            """

        let tool = MCPTool<MockInput, MockOutput>(
            name: name,
            description: description,
            inputSchema: inputSchema,
            body: { input in
                MockOutput(result: "Processed: \(input.value)")
            }
        )

        #expect(tool.name == name)
        #expect(tool.description == description)
        #expect(tool.inputSchema == inputSchema)
    }

    // Test that the tool handler works correctly
    @Test("Test MCPTool handler")
    func testMCPToolHandler() async throws {
        let tool = MCPTool<MockInput, MockOutput>(
            name: "mockTool",
            description: "A mock tool for testing",
            inputSchema: "{}",
            body: { input in
                MockOutput(result: "Processed: \(input.value)")
            }
        )

        let input = MockInput(value: "test")
        let output = try await tool.handle(input: input)

        #expect(output.result == "Processed: test")
    }

    // Test that the tool converter works correctly
    @Test("Test MCPTool converter")
    func testMCPToolConverter() async throws {
        let tool = MCPTool<MockInput, MockOutput>(
            name: "mockTool",
            description: "A mock tool for testing",
            inputSchema: "{}",
            body: { input in
                MockOutput(result: "Processed: \(input.value)")
            }
        )

        let params = CallTool.Parameters(
            name: "mockTool",
            arguments: ["value": .string("test param")]
        )

        let input = try await tool.convert(params)
        #expect(input.value == "test param")
    }

    // Test MCPServerError localized descriptions
    @Test("Test MCPServerError descriptions")
    func testMCPServerErrorDescriptions() {
        let missingParamError = MCPServerError.missingparam("testParam")
        let invalidParamError = MCPServerError.invalidParam("testParam", "invalidValue")
        let unknownToolError = MCPServerError.unknownTool("nonExistentTool")

        #expect(missingParamError.errorDescription == "Missing parameter testParam")
        #expect(invalidParamError.errorDescription == "Invalid parameter testParam with value invalidValue")
        #expect(unknownToolError.errorDescription == "Unknown tool nonExistentTool")
    }
}
