import MCP

public struct MCPTool<Input: Decodable, Output>: MCPToolProtocol {
    public let name: String
    public let description: String
    public let inputSchema: String
    let body: @Sendable (Input) async throws -> Output
    let converter: @Sendable (CallTool.Parameters) async throws -> Input

    public init(
        name: String,
        description: String,
        inputSchema: String,
        converter: @Sendable @escaping (CallTool.Parameters) async throws -> Input,
        body: @Sendable @escaping (Input) async throws -> Output
    )
    where Output: Encodable {

        self.name = name
        self.description = description
        self.inputSchema = inputSchema
        self.converter = converter
        self.body = body
    }

    public func handler(_ input: Input) async throws -> Output {
        try await self.body(input)
    }

    public func convert(_ input: CallTool.Parameters) async throws -> Input {
        return try await self.converter(input)
    }

    //FIXME: transform to generic ?
    public static func extractStringParameter(_ input: CallTool.Parameters, name: String) async throws -> String {
        
        // check if we received a "name" parameter
        guard let value = input.arguments?[name] else {
            throw MCPServerError.missingparam(name)
        }
        // extract the string value from the name parameter
        var input: String = "" 
        switch value {
        case .string(let s):
            input = s
        default:
            throw MCPServerError.invalidParam(name, "\(value)")
        }
        return input
    }

    public static func extractParameter(_ input: CallTool.Parameters, name: String) async throws -> Decodable {
        
        // check if we received a "name" parameter
        guard let value = input.arguments?[name] else {
            throw MCPServerError.missingparam(name)
        }
        // extract the string value from the name parameter
        var input: Decodable
        switch value {
        case .string(let s):
            input = s
        default:
            throw MCPServerError.invalidParam(name, "\(value)")
        }
        return input
    }    
}
