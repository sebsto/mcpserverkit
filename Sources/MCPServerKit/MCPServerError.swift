#if canImport(FoundationEssentials)
import FoundatioNEssentials
#else
import Foundation
#endif

public enum MCPServerError: Swift.Error, LocalizedError {
    case missingparam(String)
    case invalidParam(String, String)
    case unknownTool(String)

    public var errorDescription: String? {
        switch self {
        case .missingparam(let name):
            return "Missing parameter \(name)"
        case .invalidParam(let name, let value):
            return "Invalid parameter \(name) with value \(value)"
        case .unknownTool(let name):
            return "Unknown tool \(name)"
        }
    }
}
