import MCP

let prompt = MCPPrompt(
    name: "my-prompt",
    description: "my-description",
    prompt:
        "Please review this code {code:the code to review} in {language:the language of the code} programming language"
)

struct MCPPrompt {
    let prompt: MCP.Prompt? = nil

    init(
        name: String,
        description: String,
        prompt: String
    ) {

    }
}
