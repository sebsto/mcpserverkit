import Testing
import MCP
import MCPServerKit
import Foundation

@Suite("MCPServerIntegrationTests")
struct MCPServerIntegrationTests {
    
    struct SimpleInput: Codable {
        let text: String
    }
    
    struct SimpleOutput: Codable, CustomStringConvertible {
        let result: String
        
        var description: String {
            return result
        }
    }
    
    // This test verifies that we can convert CallTool.Parameters to our input type
    @Test("Test parameters conversion")
    func testParametersConversion() async throws {
        // Create a mock CallTool.Parameters
        let parameters = CallTool.Parameters(
            name: "testTool",
            arguments: ["text": .string("Hello world")]
        )
        
        // Create a tool with a converter function
        let tool = MCPTool<SimpleInput, SimpleOutput>(
            name: "testTool",
            description: "A test tool",
            inputSchema: "{}",
            converter: { params in
                guard let value = params.arguments?["text"],
                      case .string(let text) = value else {
                    throw MCPServerError.missingparam("text")
                }
                return SimpleInput(text: text)
            },
            body: { input in
                return SimpleOutput(result: "Processed: \(input.text)")
            }
        )
        
        // Test the conversion using the tool's converter
        let input = try await tool.convert(parameters)
        #expect(input.text == "Hello world")
    }
    
    // Test the extractStringParameter helper method
    @Test("Test extractStringParameter helper")
    func testExtractStringParameter() async throws {
        // Create a mock CallTool.Parameters
        let parameters = CallTool.Parameters(
            name: "testTool",
            arguments: ["text": .string("Hello world")]
        )
        
        // Use the helper method to extract the parameter
        let text = try await MCPTool<SimpleInput, SimpleOutput>.extractStringParameter(parameters, name: "text")
        #expect(text == "Hello world")
        
        // Test with missing parameter
        let emptyParams = CallTool.Parameters(name: "testTool", arguments: [:])
        do {
            _ = try await MCPTool<SimpleInput, SimpleOutput>.extractStringParameter(emptyParams, name: "text")
            #expect(Bool(false), "Expected error was not thrown")
        } catch let error as MCPServerError {
            #expect(error.errorDescription == "Missing parameter text")
        }
        
        // Test with wrong type parameter
        let wrongTypeParams = CallTool.Parameters(
            name: "testTool",
            arguments: ["text": .bool(true)]
        )
        do {
            _ = try await MCPTool<SimpleInput, SimpleOutput>.extractStringParameter(wrongTypeParams, name: "text")
            #expect(Bool(false), "Expected error was not thrown")
        } catch let error as MCPServerError {
            #expect(error.errorDescription?.contains("Invalid parameter text") == true)
        }
    }
    
    // Test error handling for unknown tools
    @Test("Test unknown tool error")
    func testUnknownToolError() {
        let error = MCPServerError.unknownTool("nonExistentTool")
        #expect(error.errorDescription == "Unknown tool nonExistentTool")
    }
    
    // Test error handling for missing parameters
    @Test("Test missing parameter error")
    func testMissingParameterError() {
        let error = MCPServerError.missingparam("requiredParam")
        #expect(error.errorDescription == "Missing parameter requiredParam")
    }
    
    // Test error handling for invalid parameters
    @Test("Test invalid parameter error")
    func testInvalidParameterError() {
        let error = MCPServerError.invalidParam("someParam", "badValue")
        #expect(error.errorDescription == "Invalid parameter someParam with value badValue")
    }
}
