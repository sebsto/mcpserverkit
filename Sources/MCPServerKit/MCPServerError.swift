#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public enum MCPServerError: Swift.Error, LocalizedError {
    case missingparam(String)
    case invalidParam(String, String)
    case unknownTool(String)
    case unknownPrompt(String)
    case resourceNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .missingparam(let name):
            return "Missing parameter \(name)"
        case .invalidParam(let name, let value):
            return "Invalid parameter \(name) with value \(value)"
        case .unknownTool(let name):
            return "Unknown tool \(name)"
        case .unknownPrompt(let name):
            return "Unknown prompt \(name)"
        case .resourceNotFound(let uri):
            return "Resource not found: \(uri)"
        }
    }
}
