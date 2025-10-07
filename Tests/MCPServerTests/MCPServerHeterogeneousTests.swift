import Foundation
import MCP
import Testing

@testable import MCPServerKit

@Suite("MCPServerHeterogeneousTests")
struct MCPServerHeterogeneousTests {

    // Mock tools for testing
    struct StringMockInput: Codable, Equatable {
        let value: String
    }

    struct StringMockOutput: Codable, Equatable {
        let result: String
    }

    struct IntMockInput: Codable, Equatable {
        let number: Int
    }

    struct IntMockOutput: Codable, Equatable {
        let doubled: Int
    }

    // Custom error for test failures
    struct TestError: Swift.Error, CustomStringConvertible {
        let description: String

        init(_ description: String) {
            self.description = description
        }
    }

    // Test that a MCPServer can be created with heterogeneous tools
    @Test("Test MCPServer initialization with heterogeneous tools")
    func testMCPServerInitialization() async throws {
        let serverName = "TestServer"
        let serverVersion = "1.0.0"

        // Create string tool
        let stringTool = MCPTool<StringMockInput, StringMockOutput>(
            name: "stringTool",
            description: "A string processing tool",
            inputSchema: """
                {
                    "type": "object",
                    "properties": {
                        "value": {
                            "type": "string"
                        }
                    },
                    "required": ["value"]
                }
                """,
            body: { input in
                StringMockOutput(result: "Processed: \(input.value)")
            }
        )

        // Create int tool using extractParameter
        let intTool = MCPTool<IntMockInput, IntMockOutput>(
            name: "intTool",
            description: "An integer processing tool",
            inputSchema: """
                {
                    "type": "object",
                    "properties": {
                        "number": {
                            "type": "integer"
                        }
                    },
                    "required": ["number"]
                }
                """,
            body: { input in
                IntMockOutput(doubled: input.number * 2)
            }
        )

        // Create server with both tools
        try await MCPServer.withMCPServer(
            name: serverName,
            version: serverVersion,
            transport: .stdio,
            tools: [stringTool, intTool]
        ) { server in

            #expect(server.name == serverName)
            #expect(server.version == serverVersion)
        }
    }

    // Test that the MCPServer can handle different tool types
    @Test("Test MCPServer tool handling")
    func testMCPServerToolHandling() async throws {
        // Create string tool
        let stringTool = MCPTool<StringMockInput, StringMockOutput>(
            name: "stringTool",
            description: "A string processing tool",
            inputSchema: """
                {
                    "type": "object",
                    "properties": {
                        "value": {
                            "type": "string"
                        }
                    },
                    "required": ["value"]
                }
                """,
            body: { input in
                StringMockOutput(result: "Processed: \(input.value)")
            }
        )

        // Create int tool using extractParameter
        let intTool = MCPTool<IntMockInput, IntMockOutput>(
            name: "intTool",
            description: "An integer processing tool",
            inputSchema: """
                {
                    "type": "object",
                    "properties": {
                        "number": {
                            "type": "integer"
                        }
                    },
                    "required": ["number"]
                }
                """,
            body: { input in
                IntMockOutput(doubled: input.number * 2)
            }
        )

        // Test string tool
        let stringParams = CallTool.Parameters(
            name: "stringTool",
            arguments: ["value": .string("test string")]
        )

        let stringResult = try await stringTool.handle(jsonInput: stringParams)

        // Verify the string result
        guard let stringOutput = stringResult as? StringMockOutput else {
            throw TestError("Expected StringMockOutput type")
        }

        #expect(stringOutput.result == "Processed: test string")

        // Test int tool with a JSON object
        let intParams = CallTool.Parameters(
            name: "intTool",
            arguments: ["number": .object(["value": .int(42)])]
        )

        // This might throw if the extractParameter method doesn't handle the object format correctly
        // That's expected and we'll handle it in a real implementation
        await #expect(throws: Swift.Error.self) { try await intTool.handle(jsonInput: intParams) }
    }

    // Test error handling in MCPServer
    @Test(
        "Test MCPServer error handling",
        arguments: [
            CallTool.Parameters(
                name: "errorTool",
                arguments: [:]
            ),
            CallTool.Parameters(
                name: "errorTool",
                arguments: ["invalid_name": .string("trigger_error")]
            ),
            CallTool.Parameters(
                name: "errorTool",
                arguments: ["value": .string("runtime_error")]
            ),
        ]
    )
    func testMCPServerErrorHandling(parameters: CallTool.Parameters) async throws {
        // Create a tool that throws errors
        let tool = MCPTool<StringMockInput, StringMockOutput>(
            name: "errorTool",
            description: "A tool that throws errors",
            inputSchema: """
                {
                    "type": "object",
                    "properties": {
                        "value": {
                            "type": "string"
                        }
                    },
                    "required": ["value"]
                }
                """,
            body: { input in
                if input.value == "runtime_error" {
                    throw MCPServerError.invalidParam("runtime", "Runtime error occurred")
                }
                return StringMockOutput(result: "Processed: \(input.value)")
            }
        )

        let error = await #expect(throws: MCPServerError.self) {
            let _ = try await tool.handle(jsonInput: parameters)
        }
        var expectedErrorMessage: String = "unknown"
        if parameters.name == "errorTool",
            let args = parameters.arguments
        {
            if args.count == 0 {
                expectedErrorMessage = "Missing parameter input"
            } else {
                for k in args.keys {
                    if k == "invalid_name" {
                        expectedErrorMessage = "Missing parameter input"
                    } else if k == "value" {
                        expectedErrorMessage = "Runtime error occurred"
                    }
                }
            }
        }
        #expect(error?.errorDescription?.contains(expectedErrorMessage) == true)
    }
}
