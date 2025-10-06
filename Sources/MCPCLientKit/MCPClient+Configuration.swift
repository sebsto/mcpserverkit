#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Structure representing the MCP configuration file format
package struct MCPConfiguration: Codable {
    let mcpServers: [String: ToolConfiguration]

    package enum ToolConfiguration: Codable {
        case stdio(ToolConfigurationStdio)
        case http(ToolConfigurationStreamable)

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            if container.contains(.command) {
                let stdio = try ToolConfigurationStdio(from: decoder)
                self = .stdio(stdio)
            } else if container.contains(.url) {
                let http = try ToolConfigurationStreamable(from: decoder)
                self = .http(http)
            } else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unable to determine tool configuration type"
                    )
                )
            }
        }

        public func encode(to encoder: Encoder) throws {
            switch self {
            case .stdio(let config):
                try config.encode(to: encoder)
            case .http(let config):
                try config.encode(to: encoder)
            }
        }

        private enum CodingKeys: String, CodingKey {
            case command, url
        }
    }
    package struct ToolConfigurationStdio: Codable {
        let command: String
        let args: [String]
        let env: [String: String]?
    }
    package struct ToolConfigurationStreamable: Codable {
        let type: String
        let url: String
        let note: String?
    }
}
