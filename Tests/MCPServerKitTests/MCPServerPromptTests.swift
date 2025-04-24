import MCP
import Testing

@testable import MCPServerKit

@Suite("MCPServer Prompt Tests")
final class MCPServerPromptTests {

    // Test creating a server with a single prompt
    @Test("Create Server With Single Prompt")
    func createServerWithSinglePrompt() throws {
        let prompt = try MCPPrompt.build { builder in
            builder.name = "test-prompt"
            builder.description = "A test prompt"
            builder.text("Hello {name}")
            builder.parameter("name", description: "The name to greet")
        }

        let server = MCPServer.create(
            name: "TestServer",
            version: "1.0.0",
            prompts: prompt
        )

        #expect(server.name == "TestServer")
        #expect(server.version == "1.0.0")
        #expect(server.prompts?.count == 1)
        #expect(server.prompts?.first?.name == "test-prompt")
        #expect(server.tools == nil)
    }

    // Test creating a server with multiple prompts
    @Test("Create Server With Multiple Prompts")
    func createServerWithMultiplePrompts() throws {
        let prompt1 = try MCPPrompt.build { builder in
            builder.name = "greeting"
            builder.description = "A greeting prompt"
            builder.text("Hello {name}")
            builder.parameter("name", description: "The name to greet")
        }

        let prompt2 = try MCPPrompt.build { builder in
            builder.name = "farewell"
            builder.description = "A farewell prompt"
            builder.text("Goodbye {name}")
            builder.parameter("name", description: "The name to bid farewell")
        }

        let server = MCPServer.create(
            name: "TestServer",
            version: "1.0.0",
            prompts: prompt1,
            prompt2
        )

        #expect(server.prompts?.count == 2)
        #expect(server.prompts?.map(\.name).contains("greeting") == true)
        #expect(server.prompts?.map(\.name).contains("farewell") == true)
    }

    // Test creating a server with both tools and prompts
    @Test("Create Server With Tools And Prompts")
    func createServerWithToolsAndPrompts() throws {
        // Create a simple tool for testing
        let tool = MCPTool<String, String>(
            name: "echo",
            description: "Echo tool",
            inputSchema: """
                {
                    "type": "object",
                    "properties": {
                        "message": {
                            "type": "string",
                            "description": "Message to echo"
                        }
                    },
                    "required": ["message"]
                }
                """,
            converter: { params in
                try MCPTool<String, String>.extractParameter(params, name: "message")
            },
            body: { message in
                return message
            }
        )

        let prompt = try MCPPrompt.build { builder in
            builder.name = "test-prompt"
            builder.description = "A test prompt"
            builder.text("Hello {name}")
            builder.parameter("name", description: "The name to greet")
        }

        let server = MCPServer.create(
            name: "TestServer",
            version: "1.0.0",
            tools: [tool],
            prompts: [prompt]
        )

        #expect(server.tools?.count == 1)
        #expect(server.prompts?.count == 1)
        #expect(server.tools?.first?.name == "echo")
        #expect(server.prompts?.first?.name == "test-prompt")
    }

    // Test prompt conversion to MCP Prompt
    @Test("Prompt Conversion To MCP Prompt")
    func promptConversionToMCPPrompt() throws {
        let prompt = try MCPPrompt.build { builder in
            builder.name = "test-prompt"
            builder.description = "A test prompt"
            builder.text("Hello {name} and {greeting}")
            builder.parameter("name", description: "The name to greet")
            builder.parameter("greeting", description: "The greeting to use")
        }

        let mcpPrompt = prompt.toPrompt()

        #expect(mcpPrompt.name == "test-prompt")
        #expect(mcpPrompt.description == "A test prompt")
        #expect(mcpPrompt.arguments?.count == 2)

        // Check that all parameters are included in the arguments
        if let arguments = mcpPrompt.arguments {
            let argumentNames = arguments.map(\.name)
            #expect(argumentNames.contains("name"))
            #expect(argumentNames.contains("greeting"))

            // Check that all arguments are marked as required
            for argument in arguments {
                #expect(argument.required == true)
            }
        } else {
            Issue.record("Expected arguments to be non-nil")
        }
    }

    // Test prompt conversion to Message
    @Test("Prompt Conversion To Message")
    func promptConversionToMessage() throws {
        let prompt = try MCPPrompt.build { builder in
            builder.name = "test-prompt"
            builder.description = "A test prompt"
            builder.text("Hello {name}")
            builder.parameter("name", description: "The name to greet")
        }

        let message = try prompt.toMessage(with: ["name": "Alice"])

        #expect(message.role == .user)
        if case .text(let text) = message.content {
            #expect(text == "Hello Alice")
        } else {
            Issue.record("Expected text content in message")
        }
    }

    // Test prompt conversion to Message with missing parameter
    @Test("Prompt Conversion To Message With Missing Parameter")
    func promptConversionToMessageWithMissingParameter() throws {
        let prompt = try MCPPrompt.build { builder in
            builder.name = "test-prompt"
            builder.description = "A test prompt"
            builder.text("Hello {name}")
            builder.parameter("name", description: "The name to greet")
        }

        let error = #expect(throws: PromptError.self) {
            try prompt.toMessage(with: [:])
        }

        if case .missingParameterValue(let parameter) = error {
            #expect(parameter == "name")
        } else {
            Issue.record("Expected missingParameterValue error")
        }
    }

    // Test registering prompts with a server
    @Test("Register Prompts With Server")
    func registerPromptsWithServer() throws {
        let prompt1 = try MCPPrompt.build { builder in
            builder.name = "greeting"
            builder.description = "A greeting prompt"
            builder.text("Hello {name}")
            builder.parameter("name", description: "The name to greet")
        }

        let prompt2 = try MCPPrompt.build { builder in
            builder.name = "farewell"
            builder.description = "A farewell prompt"
            builder.text("Goodbye {name}")
            builder.parameter("name", description: "The name to bid farewell")
        }

        // Create a server with the prompts
        let server = MCPServer.create(
            name: "TestServer",
            version: "1.0.0",
            prompts: prompt1,
            prompt2
        )

        // Verify the server has the prompts
        #expect(server.prompts?.count == 2)
        #expect(server.prompts?.contains(where: { $0.name == "greeting" }) == true)
        #expect(server.prompts?.contains(where: { $0.name == "farewell" }) == true)
    }
}
