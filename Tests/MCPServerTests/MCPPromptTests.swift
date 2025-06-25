import Testing

@testable import MCPServerKit

@Suite("MCPPrompt Tests")
final class MCPPromptTests {

    @Test("Basic Prompt Creation")
    func createBasicPrompt() throws {
        let prompt = try MCPPrompt.build { builder in
            builder.name = "test-prompt"
            builder.description = "A test prompt"
            builder.text("Hello {name}")
            builder.parameter("name", description: "The name to greet")
        }

        #expect(prompt.name == "test-prompt")
        #expect(prompt.description == "A test prompt")
        #expect(prompt.template == "Hello {name}")
        #expect(prompt.parameters["name"] == "The name to greet")
    }

    @Test("Missing Parameter Validation")
    func missingParameter() {
        let error = #expect(throws: PromptError.self) {
            try MCPPrompt.build { builder in
                builder.name = "test"
                builder.description = "test"
                builder.text("Hello {name}")
                // Missing parameter definition for "name"
            }
        }

        if case .missingParameters(let parameters) = error {
            #expect(parameters == ["name"])
        } else {
            Issue.record("Expected missingParameters error")
        }
    }

    @Test("Extra Parameter Validation")
    func extraParameter() {
        let error = #expect(throws: PromptError.self) {
            try MCPPrompt.build { builder in
                builder.name = "test"
                builder.description = "test"
                builder.text("Hello world")
                builder.parameter("name", description: "unused parameter")
            }
        }

        if case .extraParameters(let parameters) = error {
            #expect(parameters == ["name"])
        } else {
            Issue.record("Expected extraParameters error")
        }
    }

    @Test("Prompt Rendering")
    func renderPrompt() throws {
        let prompt = try MCPPrompt.build { builder in
            builder.name = "greeting"
            builder.description = "A greeting prompt"
            builder.text("Hello {name}, welcome to {place}")
            builder.parameter("name", description: "The name to greet")
            builder.parameter("place", description: "The place to welcome to")
        }

        let rendered = try prompt.render(with: [
            "name": "Alice",
            "place": "Wonderland",
        ])

        #expect(rendered == "Hello Alice, welcome to Wonderland")
    }

    @Test("Render Missing Value")
    func renderMissingValue() throws {
        let prompt = try MCPPrompt.build { builder in
            builder.name = "test"
            builder.description = "test"
            builder.text("Hello {name}")
            builder.parameter("name", description: "The name")
        }

        let error = #expect(throws: PromptError.self) {
            try prompt.render(with: [:])
        }

        if case .missingParameterValue(let parameter) = error {
            #expect(parameter == "name")
        } else {
            Issue.record("Expected missingParameterValue error")
        }
    }

    @Test("Render With Extra Values")
    func renderWithExtraValues() throws {
        let prompt = try MCPPrompt.build { builder in
            builder.name = "test"
            builder.description = "test"
            builder.text("Hello {name}")
            builder.parameter("name", description: "The name")
        }

        let rendered = try prompt.render(with: [
            "name": "Alice",
            "extra": "value",  // This should be ignored
        ])

        #expect(rendered == "Hello Alice")
    }

    @Test("Multiple Parameters")
    func multipleParameters() throws {
        let prompt = try MCPPrompt.build { builder in
            builder.name = "code-review"
            builder.description = "A code review prompt"
            builder.text("Please review this {code} in {language}")
            builder.parameter("code", description: "The code to review")
            builder.parameter("language", description: "The programming language")
        }

        let rendered = try prompt.render(with: [
            "code": "print('Hello')",
            "language": "Python",
        ])

        #expect(rendered == "Please review this print('Hello') in Python")
    }

    @Test("Empty Template")
    func emptyTemplate() throws {
        let prompt = try MCPPrompt.build { builder in
            builder.name = "empty"
            builder.description = "An empty prompt"
            builder.text("")
        }

        let rendered = try prompt.render(with: [:])
        #expect(rendered == "")
    }

    @Test("Template With No Parameters")
    func templateWithNoParameters() throws {
        let prompt = try MCPPrompt.build { builder in
            builder.name = "static"
            builder.description = "A static prompt"
            builder.text("This is a static message")
        }

        let rendered = try prompt.render(with: [:])
        #expect(rendered == "This is a static message")
    }

    @Test("Nested Braces")
    func nestedBraces() throws {
        let prompt = try MCPPrompt.build { builder in
            builder.name = "nested"
            builder.description = "A prompt with nested braces"
            builder.text("This is {not_a_parameter} but this is {parameter}")
            builder.parameter("not_a_parameter", description: "A non-parameter")
            builder.parameter("parameter", description: "A parameter")
        }

        let rendered = try prompt.render(with: [
            "not_a_parameter": "{still_not_a_parameter}",
            "parameter": "value",
        ])

        #expect(rendered == "This is {still_not_a_parameter} but this is value")
    }
}
