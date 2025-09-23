import Foundation
import MCP
import MCPServerKit
import Testing

@Suite("ToolProtocolTests")
struct ToolProtocolTests {

    // Custom error for test failures
    struct TestError: Swift.Error, CustomStringConvertible {
        let description: String

        init(_ description: String) {
            self.description = description
        }
    }

    // Mock implementation of ToolProtocol for testing
    struct MockTool<I: Decodable, O: Encodable>: ToolProtocol {
        typealias Input = I
        typealias Output = O

        let name: String
        let description: String
        let inputSchema: String
        let mockHandler: @Sendable (I) async throws -> O
        let mockConverter: @Sendable (CallTool.Parameters) async throws -> I

        func handle(input: I) async throws -> O {
            try await mockHandler(input)
        }

        func convert(_ input: CallTool.Parameters) async throws -> I {
            try await mockConverter(input)
        }

        func handle(jsonInput: CallTool.Parameters) async throws -> Encodable {
            let input = try await convert(jsonInput)
            return try await handler(input: input)
        }
    }

    struct TestInput: Codable, Equatable {
        let message: String
    }

    struct TestOutput: Codable, Equatable {
        let response: String
    }

    @Test("Test ToolProtocol conformance")
    func testToolProtocolConformance() async throws {
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
                TestOutput(response: "Echo: \(input.message)")
            },
            mockConverter: { params in
                guard let value = params.arguments?["message"],
                    case .string(let message) = value
                else {
                    throw MCPServerError.missingparam("message")
                }
                return TestInput(message: message)
            }
        )

        #expect(tool.name == "testTool")
        #expect(tool.description == "A test tool")

        let input = TestInput(message: "Hello")
        let output = try await tool.handler(input: input)

        #expect(output.response == "Echo: Hello")

        // Test converter
        let params = CallTool.Parameters(
            name: "testTool",
            arguments: ["message": .string("Hello from params")]
        )
        let convertedInput = try await tool.convert(params)
        #expect(convertedInput.message == "Hello from params")

        // Test handle method
        let jsonOutput = try await tool.handle(jsonInput: params)
        guard let testOutput = jsonOutput as? TestOutput else {
            throw TestError("Expected TestOutput type")
        }
        #expect(testOutput.response == "Echo: Hello from params")
    }
}
