import MCP

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation	
#endif

/// An adapter that provides default implementations of convert() and handle() for 
/// Decodable and encodable
public extension MCPToolProtocol {
		// func convert(_ input: CallTool.Parameters) async throws -> Input where Input: Decodable {
    //     let data = try JSONEncoder().encode(input.arguments)
    //     return try JSONDecoder().decode(Input.self, from: data)
    // }
    
    // func handle(jsonInput: CallTool.Parameters) async throws -> Self.Output {
    //     let convertedInput = try await convert(jsonInput)
    //     return try await handler(input: convertedInput)
    // }

}