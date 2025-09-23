import MCP

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A MCPTool implementation that deals with JSON input and output
public struct MCPTool<Input: Decodable, Output: Encodable>: ToolProtocol {
    public let name: String
    public let description: String
    public let inputSchema: String
    public let customConverter: (@Sendable (CallTool.Parameters) async throws -> Input)?
    public let body: @Sendable (Input) async throws -> Output

    public init(
        name: String,
        description: String,
        inputSchema: String,
        converter: @escaping @Sendable (CallTool.Parameters) async throws -> Input,
        body: @Sendable @escaping (Input) async throws -> Output
    ) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
        self.customConverter = converter
        self.body = body
    }
    public init(
        name: String,
        description: String,
        inputSchema: String,
        body: @Sendable @escaping (Input) async throws -> Output
    ) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
        self.customConverter = nil
        self.body = body
    }

    public func handle(input: Input) async throws -> Output {
        try await self.body(input)
    }

    public func convert(_ input: CallTool.Parameters) async throws -> Input {
        if let converter = self.customConverter {
            // Use the provided converter if available
            return try await converter(input)
        } else {
            // Default conversion using the static method
            return try Self.extractParameter(input, name: "input")
        }
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
        guard let value = input.arguments?[name] else {
            throw MCPServerError.missingparam(name)
        }

        // FIXME: is this the most efficient way to do this?
        // extract the data value from the named parameter
        let data = try JSONEncoder().encode(value)
        // decode the data into the expected type
        return try JSONDecoder().decode(Input.self, from: data)
    }

}
