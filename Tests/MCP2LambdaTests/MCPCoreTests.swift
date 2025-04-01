import Testing
@testable import MCPCore

@Suite("MCPCore Tests")
struct MCPCoreTests {
    @Test("MCPTool creation and properties")
    func mcpToolCreation() throws {
        let tool = MCPTool(
            name: "test-tool",
            description: "A test tool",
            parameters: [
                "param1": MCPParameter(type: "string", description: "Parameter 1", required: true),
                "param2": MCPParameter(type: "number", description: "Parameter 2", required: false)
            ]
        )
        
        #expect(tool.name == "test-tool")
        #expect(tool.description == "A test tool")
        #expect(tool.parameters.count == 2)
        #expect(tool.parameters["param1"]?.type == "string")
        #expect(tool.parameters["param1"]?.description == "Parameter 1")
        #expect(tool.parameters["param1"]?.required == true)
        #expect(tool.parameters["param2"]?.type == "number")
        #expect(tool.parameters["param2"]?.description == "Parameter 2")
        #expect(tool.parameters["param2"]?.required == false)
    }
    
    @Test("MCPContext logging methods")
    func mcpContextLogging() throws {
        let context = MCPContext()
        
        // These methods don't return anything, so we're just testing that they don't crash
        context.info("Test info message")
        context.error("Test error message")
        context.warning("Test warning message")
        
        // In a more comprehensive test, we might capture stdout and verify the output
        #expect(true)
    }
}
