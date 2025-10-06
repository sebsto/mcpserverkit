import MCP

extension MCPPrompt {
    /// Converts this MCPPrompt to a swift-sdk Prompt
    public func toPrompt() -> Prompt {
        let arguments = parameters.map { (name, description) in
            Prompt.Argument(
                name: name,
                description: description,
                required: true  // All parameters in MCPPrompt are required
            )
        }

        return Prompt(
            name: name,
            description: description,
            arguments: arguments
        )
    }

    /// Creates a Message from this prompt with the given values
    public func toMessage(with values: [String: String]) throws -> Prompt.Message {
        let rendered = try render(with: values)
        // the below line is from the Swift MCP project main branch
        // return Prompt.Message.user(.text(text: rendered))
        // this is from the fork (that lags a bit behind)
        return Prompt.Message.init(role: .user, content: .text(text: rendered))
    }
}
