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
        if let result = try? JSONDecoder().decode(Input.self, from: data) {
            return result
        } else {
            return try Self.extractParameter(input, name: "input")
        }
    }

    public func handle(jsonInput: CallTool.Parameters) async throws -> Encodable {
        let convertedInput: Self.Input!
        convertedInput = try await convert(jsonInput)
        return try await handle(input: convertedInput)
    }

    /// Extracts a parameter from the input dictionary and decodes it into the expected type.
    /// You can use this function in your `converter` closure to extract parameters from the input dictionary.
    /// - Parameters:
    ///   - input: The input dictionary containing the parameters.
    ///   - name: The name of the parameter to extract.
    /// - Throws: An error if the parameter is missing or cannot be decoded into the expected type.
    /// - Returns: The decoded parameter of the expected type.
    /// - Note: This function is generic and can be used with any type that conforms to `Codable`.
    /// - Important: The parameter must be a valid JSON object that can be decoded into the expected type.
    /// - Warning: This function uses `JSONEncoder` and `JSONDecoder` to encode and decode the parameter, which may not be the most efficient way to handle this.
    public static func extractParameter(_ input: CallTool.Parameters, name: String) throws -> Input {
        // check if we received a "name" parameter
        guard let value: Value = input.arguments?[name] else {
            throw MCPServerError.missingparam(name)
        }

        // FIXME: is this the most efficient way to do this?
        // extract the data value from the named parameter
        let data = try JSONEncoder().encode(value)
        // decode the data into the expected type
        return try JSONDecoder().decode(Input.self, from: data)
    }
}
