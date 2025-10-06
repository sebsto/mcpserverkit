import BedrockService

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

// Default implementations for tools with Codable Input types
extension ToolProtocol {
    // convert the input from the JSON to the expected type
    public func convert(_ input: JSON) async throws -> Input {
        // when Tool handler is (input:Input), decode the "input" key
        if let value: Input = input["input"] {
            return value
        } else {
            // otherwise transform the JSON to Input
            let data = try JSONEncoder().encode(input)
            return try JSONDecoder().decode(Input.self, from: data)
        }
    }
    public func handle(jsonInput: JSON) async throws -> Output {
        let convertedInput = try await convert(jsonInput)
        return try await handle(input: convertedInput)
    }
}
