import MCP

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public protocol MCPToolProtocol<Input, Output>: ToolProtocol {

    // convert the input from the CallTool.Parameters to the expected type
    func convert(_ input: CallTool.Parameters) async throws -> Input

    // handle JSON input and return a result that can be converted to JSON
    func handle(jsonInput: CallTool.Parameters) async throws -> Encodable
}

// Default implementations for tools with Codable Input types
extension MCPToolProtocol where Input: Decodable, Output: Encodable {
    public func convert(_ input: CallTool.Parameters) async throws -> Input {
        let data = try JSONEncoder().encode(input.arguments)
        return try JSONDecoder().decode(Input.self, from: data)
    }

    public func handle(jsonInput: CallTool.Parameters) async throws -> Encodable {
        let convertedInput = try await convert(jsonInput)
        return try await handle(input: convertedInput)
    }
}
