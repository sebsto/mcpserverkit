import BedrockService
import Logging

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
        messages: inout History,
        logger: Logger
    ) async throws -> ConverseRequestBuilder {

        guard let message = messages.last else {
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
        let textResult = try await callTool(
            tool: tool,
            arguments: toolUse.input,
            logger: logger
        )
        logger.trace("Tool Result", metadata: ["result": "\(textResult)"])

        // pass the result back to the model
        // when the result is a simple string, we must pass it as a String object 
        // (because the ToolResultBlock's content is an enum that makes the distinction between string and json)
        if let string = isString(textResult) {
            return try ConverseRequestBuilder(from: requestBuilder, with: message).withToolResult(string)
        } else {
            return try ConverseRequestBuilder(from: requestBuilder, with: message).withToolResult(textResult)
        }
    }

    private func isString(_ value: Encodable) -> String? {
        guard let string = try? String(data: JSONEncoder().encode(value), encoding: .utf8) else { 
            return nil
        }
        return string
    }

    private func callTool<Tool: ToolProtocol>(
        tool: Tool,
        arguments: JSON,
        logger: Logger
    ) async throws -> Tool.Output  where Tool.Input: Decodable, Tool.Output: Encodable{

        let result: Tool.Output!
        do {

            // call the tool with the provided arguments
            result = try await tool.handle(jsonInput: arguments)
            
            logger.trace(
                "Tool result",
                metadata: ["result": "\(String(describing:result))"]
            )

        } catch {
            logger.error("Tool threw an error: \(error)")
            throw error
        }

        return result
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
