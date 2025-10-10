import BedrockService
import Logging
import MCPShared

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension Agent {
    var toolNames: [String] {
        self.tools.map { $0.name }
    }

    func resolveToolUse(
        bedrock: BedrockService,
        requestBuilder: ConverseRequestBuilder,
        tools: [any ToolProtocol],
        toolUse: ToolUseBlock,
        messages: History,
        logger: Logger
    ) async throws -> ConverseRequestBuilder {

        guard messages.last != nil else {
            fatalError(
                "No last message found in the history to resolve tool use"
            )
        }

        // find the tool
        guard let tool = tools.tool(named: toolUse.name) else {
            throw AgentError.toolNotFound(toolUse.name)
        }
        logger.trace(
            "Tool found, going to call it",
            metadata: ["name": "\(toolUse.name)", "input": "\(toolUse.input)"]
        )

        // invoke the tool
        let result = try await tool.handle(jsonInput: toolUse.input)
        logger.trace("Tool Result", metadata: ["result": "\(result)"])

        // pass the result back to the model
        // when the result is a simple string, we must pass it as a String object
        // (because the ToolResultBlock's content is an enum that makes the distinction between string and json)
        if let string = isString(result) {
            return try ConverseRequestBuilder(from: requestBuilder)
                .withHistory(messages)
                .withToolResult(string)
        } else {
            return try ConverseRequestBuilder(from: requestBuilder)
                .withHistory(messages)
                .withToolResult(result)
        }
    }

    private func isString(_ value: Encodable) -> String? {
        guard let string = try? String(data: JSONEncoder().encode(value), encoding: .utf8) else {
            return nil
        }
        return string
    }
}

extension ToolProtocol {
    public func bedrockTool() throws -> Tool {
        let json = try JSON(from: self.inputSchema)
        return try Tool(name: self.name, inputSchema: json, description: self.description)
    }
}

extension Array where Element == any ToolProtocol {
    public func bedrockTools() throws -> [Tool] {
        try self.map { try $0.bedrockTool() }
    }
    public func tool(named toolName: String) -> (any ToolProtocol)? {
        self.first(where: { $0.name == toolName })
    }
}
