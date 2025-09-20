import BedrockService
import Logging

extension Agent {
	var toolNames: [String] {
		self.tools.map { $0.name }
	}

    // private func resolveToolUse(
    //     bedrock: BedrockService,
    //     requestBuilder: ConverseRequestBuilder,
    //     tools: [any ToolProtocol],
    //     toolUse: ToolUseBlock,
    //     messages: inout History,
    //     logger: Logger
    // ) async throws -> ConverseRequestBuilder {

    //     guard let message = messages.last else {
    //         fatalError(
    //             "No last message found in the history to resolve tool use"
    //         )
    //     }

    //     // convert swift-bedrock-library's input to a MCP swift-sdk [String: Value]?
    //     let mcpToolInput = try toolUse.input.toMCPInput()

    //     // log the tool use
    //     logger.trace("Tool Use", metadata: ["name": "\(toolUse.name)", "input": "\(mcpToolInput)"])

    //     // invoke the tool
    //     let textResult = try await tools.callTool(
    //         name: toolUse.name,
    //         arguments: mcpToolInput,
    //         logger: logger
    //     )
    //     logger.trace("Tool Result", metadata: ["result": "\(textResult)"])

    //     // pass the result back to the model
    //     return try ConverseRequestBuilder(from: requestBuilder, with: message)
    //         .withToolResult(textResult)
    // }
}

extension ToolProtocol {
    public func bedrockTool() throws -> Tool {
			let json = try JSON(from: self.inputSchema)
			return try Tool(name: self.name, inputSchema: json, description: self.description)
		}
}

extension Array where Element == any ToolProtocol {
	public func bedrockTools() throws -> [Tool] {
		return try self.map { try $0.bedrockTool() }
	}
}


