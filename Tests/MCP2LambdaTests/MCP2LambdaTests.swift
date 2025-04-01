import Testing
@testable import MCP2Lambda
@testable import MCPCore

@Suite("MCP2Lambda Tests")
struct MCP2LambdaTests {
    @Test("Sanitize tool name removes prefix")
    func sanitizeToolNameRemovesPrefix() throws {
        let command = MCP2Lambda()
        #expect(command.sanitizeToolName("mcp2lambda-test-function", prefix: "mcp2lambda-") == "test_function")
    }
    
    @Test("Sanitize tool name replaces invalid characters")
    func sanitizeToolNameReplacesInvalidChars() throws {
        let command = MCP2Lambda()
        #expect(command.sanitizeToolName("function-with-hyphens", prefix: "") == "function_with_hyphens")
    }
    
    @Test("Sanitize tool name handles numbers at beginning")
    func sanitizeToolNameHandlesLeadingNumbers() throws {
        let command = MCP2Lambda()
        #expect(command.sanitizeToolName("123function", prefix: "") == "_123function")
    }
    
    @Test("Sanitize tool name handles complex scenarios")
    func sanitizeToolNameHandlesComplexScenarios() throws {
        let command = MCP2Lambda()
        #expect(command.sanitizeToolName("mcp2lambda-123-test-function!", prefix: "mcp2lambda-") == "_123_test_function_")
    }
    
    @Test("Validate function name with prefix")
    func validateFunctionNameWithPrefix() throws {
        let command = MCP2Lambda()
        #expect(command.validateFunctionName("mcp2lambda-test", prefix: "mcp2lambda-", allowedList: []))
        #expect(!command.validateFunctionName("other-test", prefix: "mcp2lambda-", allowedList: []))
    }
    
    @Test("Validate function name with allowed list")
    func validateFunctionNameWithAllowedList() throws {
        let command = MCP2Lambda()
        #expect(command.validateFunctionName("special-function", prefix: "mcp2lambda-", allowedList: ["special-function"]))
        #expect(!command.validateFunctionName("not-allowed", prefix: "mcp2lambda-", allowedList: ["special-function"]))
    }
    
    @Test("Validate function name with combined criteria")
    func validateFunctionNameWithCombinedCriteria() throws {
        let command = MCP2Lambda()
        #expect(command.validateFunctionName("mcp2lambda-test", prefix: "mcp2lambda-", allowedList: ["special-function"]))
        #expect(command.validateFunctionName("special-function", prefix: "mcp2lambda-", allowedList: ["special-function"]))
    }
}
