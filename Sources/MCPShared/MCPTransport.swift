public enum MCPTransport: Sendable {
    case stdio
    case http(port: Int)
}
