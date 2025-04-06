import Testing
import MCPServerKit
import MCP
import Foundation

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
            converter: { params in
                guard let value = params.arguments?["query"],
                      case .string(let query) = value else {
                    throw MCPServerError.missingparam("query")
                }
                return TestInput(query: query)
            },
            body: { input in
                return TestOutput(answer: "Response to: \(input.query)")
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
            converter: { params in
                guard let value = params.arguments?["query"],
                      case .string(let query) = value else {
                    throw MCPServerError.missingparam("query")
                }
                return TestInput(query: query)
            },
            body: { input in
                return TestOutput(answer: "Response to: \(input.query)")
            }
        )
        
        let input = TestInput(query: "What is the weather?")
        let output = try await tool.handler(input)
        
        #expect(output.answer == "Response to: What is the weather?")
    }
    
    @Test("Test MCPTool with error handling")
    func testMCPToolWithErrorHandling() async throws {
        enum TestError: Error {
            case invalidQuery
        }
        
        let tool = MCPTool<TestInput, TestOutput>(
            name: "errorTool",
            description: "Tool that might throw errors",
            inputSchema: "{}",
            converter: { params in
                guard let value = params.arguments?["query"],
                      case .string(let query) = value else {
                    throw MCPServerError.missingparam("query")
                }
                return TestInput(query: query)
            },
            body: { input in
                if input.query.isEmpty {
                    throw TestError.invalidQuery
                }
                return TestOutput(answer: "Valid query: \(input.query)")
            }
        )
        
        // Test with valid input
        let validInput = TestInput(query: "valid query")
        let output = try await tool.handler(validInput)
        #expect(output.answer == "Valid query: valid query")
        
        // Test with invalid input that should throw
        let invalidInput = TestInput(query: "")
        do {
            _ = try await tool.handler(invalidInput)
            #expect(Bool(false), "Expected error was not thrown")
        } catch is TestError {
            // Expected error was thrown
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }
}
