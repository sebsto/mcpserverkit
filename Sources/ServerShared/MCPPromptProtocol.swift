// Forward declaration for MCPPrompt to avoid circular dependency
// The actual implementation is in MCPServerKit
public protocol MCPPromptProtocol: Sendable {
    var name: String { get }
    var description: String { get }
    var template: String { get }
    var parameters: [String: String] { get }
}
