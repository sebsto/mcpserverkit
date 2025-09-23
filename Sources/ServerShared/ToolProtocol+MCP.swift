import MCP

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

// Default implementations for MCP tools 
extension ToolProtocol {
    public func convert(_ input: CallTool.Parameters) async throws -> Input {
        let data = try JSONEncoder().encode(input.arguments)
        return try JSONDecoder().decode(Input.self, from: data)
    }

    public func handle(jsonInput: CallTool.Parameters) async throws -> Encodable {
        let convertedInput = try await convert(jsonInput)
        return try await handle(input: convertedInput)
    }
}
