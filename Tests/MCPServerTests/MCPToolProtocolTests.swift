import Testing
import MCPServerKit
import MCP
import Foundation

@Suite("MCPToolProtocolTests")
struct MCPToolProtocolTests {
    
    // Mock implementation of MCPToolProtocol for testing
    struct MockTool<I: Decodable, O>: MCPToolProtocol {
        typealias Input = I
        typealias Output = O
        
        let name: String
        let description: String
        let inputSchema: String
        let mockHandler: @Sendable (I) async throws -> O
        let mockConverter: @Sendable (CallTool.Parameters) async throws -> I
        
        func handler(_ input: I) async throws -> O {
            return try await mockHandler(input)
        }
        
        func convert(_ input: CallTool.Parameters) async throws -> I {
            return try await mockConverter(input)
        }
    }
    
    struct TestInput: Codable, Equatable {
        let message: String
    }
    
    struct TestOutput: Codable, Equatable {
        let response: String
    }
    
    @Test("Test MCPToolProtocol conformance")
    func testMCPToolProtocolConformance() async throws {
        let tool = MockTool<TestInput, TestOutput>(
            name: "testTool",
            description: "A test tool",
            inputSchema: """
            {
                "type": "object",
                "properties": {
                    "message": {
                        "type": "string"
                    }
                },
                "required": ["message"]
            }
            """,
            mockHandler: { input in
                return TestOutput(response: "Echo: \(input.message)")
            },
            mockConverter: { params in
                guard let value = params.arguments?["message"],
                      case .string(let message) = value else {
                    throw MCPServerError.missingparam("message")
                }
                return TestInput(message: message)
            }
        )
        
        #expect(tool.name == "testTool")
        #expect(tool.description == "A test tool")
        
        let input = TestInput(message: "Hello")
        let output = try await tool.handler(input)
        
        #expect(output.response == "Echo: Hello")
        
        // Test converter
        let params = CallTool.Parameters(
            name: "testTool",
            arguments: ["message": .string("Hello from params")]
        )
        let convertedInput = try await tool.convert(params)
        #expect(convertedInput.message == "Hello from params")
    }
}
