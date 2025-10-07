import Foundation
import MCP
import MCPServerKit
import Testing

@Suite("MCPToolTests")
struct MCPToolTests {

    struct TestInput: Codable, Equatable {
        let query: String
    }

    struct TestOutput: Codable, Equatable {
        let answer: String
    }

    @Test("Test MCPTool creation and properties")
    func testMCPToolCreation() {
        let name = "testTool"
        let description = "A test tool for unit testing"
        let inputSchema = """
            {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "The query to process"
                    }
                },
                "required": ["query"]
            }
            """

        let tool = MCPTool<TestInput, TestOutput>(
            name: name,
            description: description,
            inputSchema: inputSchema,
            body: { input in
                TestOutput(answer: "Response to: \(input.query)")
            }
        )

        #expect(tool.name == name)
        #expect(tool.description == description)
        #expect(tool.inputSchema == inputSchema)
    }

    @Test("Test MCPTool handler execution")
    func testMCPToolHandlerExecution() async throws {
        let tool = MCPTool<TestInput, TestOutput>(
            name: "queryTool",
            description: "Processes queries",
            inputSchema: "{}",
            body: { input in
                TestOutput(answer: "Response to: \(input.query)")
            }
        )

        let input = TestInput(query: "What is the weather?")
        let output = try await tool.handle(input: input)

        #expect(output.answer == "Response to: What is the weather?")
    }

    @Test("Test MCPTool with error handling")
    func testMCPToolWithErrorHandling() async throws {
        enum TestError: Swift.Error, CustomStringConvertible {
            case invalidQuery

            var description: String {
                switch self {
                case .invalidQuery:
                    return "Invalid query provided"
                }
            }
        }

        let tool = MCPTool<TestInput, TestOutput>(
            name: "errorTool",
            description: "Tool that might throw errors",
            inputSchema: "{}",
            body: { input in
                if input.query.isEmpty {
                    throw TestError.invalidQuery
                }
                return TestOutput(answer: "Valid query: \(input.query)")
            }
        )

        // Test with valid input
        let validInput = TestInput(query: "valid query")
        let output = try await tool.handle(input: validInput)
        #expect(output.answer == "Valid query: valid query")

        // Test with invalid input that should throw
        let invalidInput = TestInput(query: "")
        do {
            _ = try await tool.handle(input: invalidInput)
            #expect(Bool(false), "Expected error was not thrown")
        } catch let error as TestError {
            #expect(error == .invalidQuery)
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }
}
