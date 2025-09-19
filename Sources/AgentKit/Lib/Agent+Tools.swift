import BedrockService

import Foundation 

extension Agent {
	var toolNames: [String] {
		self.tools.map { $0.name }
	}

	/// Converts an array of existential ToolProtocol types to Bedrock Tools
	// internal func convertToBedrockTools(_ tools: [any ToolProtocol]) throws -> [Tool] {
	// 		return try tools.map { try $0.bedrockTool() }
	// }
}

extension ToolProtocol {
    public func bedrockTool() throws -> Tool {

			let json = try JSON(from: self.inputSchema)

			print(" INPUT SCHEMA  ")
			print(self.inputSchema)
			print("      JSON     ")
			print(json) 

			// encode teh JSON to a string 
			let jsonString = String(data: try JSONEncoder().encode(json), encoding: .utf8) ?? ""

			print(" JSON STRING ")
			print(jsonString)

			return try Tool(name: self.name, inputSchema: json, description: self.description)
		}
}

extension Array where Element == any ToolProtocol {
	public func bedrockTools() throws -> [Tool] {
		return try self.map { try $0.bedrockTool() }
	}
}


