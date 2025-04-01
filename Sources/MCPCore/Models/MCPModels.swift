import Foundation
import Vapor

/// Models for the Model Context Protocol (MCP)

/// Represents a tool that can be used by the model
public struct MCPTool: Codable, Content {
    public let name: String
    public let description: String
    public let parameters: [String: MCPParameter]
    
    public init(name: String, description: String, parameters: [String: MCPParameter]) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}

/// Represents a parameter for a tool
public struct MCPParameter: Codable, Content {
    public let type: String
    public let description: String
    public let required: Bool
    
    public init(type: String, description: String, required: Bool = false) {
        self.type = type
        self.description = description
        self.required = required
    }
}

/// Response from listing available tools
public struct MCPToolsResponse: Codable, Content {
    public let tools: [MCPTool]
    
    public init(tools: [MCPTool]) {
        self.tools = tools
    }
}

/// Request to call a tool
public struct MCPToolCallRequest: Codable, Content {
    public let name: String
    public let arguments: [String: AnyCodable]
    
    public init(name: String, arguments: [String: Any]) {
        self.name = name
        self.arguments = arguments.mapValues { AnyCodable($0) }
    }
    
    public init(name: String, arguments: [String: AnyCodable]) {
        self.name = name
        self.arguments = arguments
    }
}

/// A type-erasing wrapper for Codable values
/// Note: Explicitly not conforming to Sendable due to Any storage
public struct AnyCodable: Codable, Content, @unchecked Sendable {
    @usableFromInline
    internal let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = Optional<Any>.none as Any
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable cannot decode value"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self.value {
        case is NSNull:
            try container.encodeNil()
        case let optional as Optional<Any> where optional == nil:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "AnyCodable cannot encode value of type \(type(of: self.value))"
            )
            throw EncodingError.invalidValue(self.value, context)
        }
    }
    
    /// Get the underlying value as its actual type
    public var unwrapped: Any {
        return value
    }
}

/// Response from calling a tool
public struct MCPToolCallResponse: Codable, Content {
    public let result: String
    
    public init(result: String) {
        self.result = result
    }
}

/// Context for tool execution
public class MCPContext {
    public init() {}
    
    public func info(_ message: String) {
        print("[INFO] \(message)")
    }
    
    public func error(_ message: String) {
        print("[ERROR] \(message)")
    }
    
    public func warning(_ message: String) {
        print("[WARNING] \(message)")
    }
}
