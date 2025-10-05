import ServiceLifecycle

extension MCPServer: Service {
    public func run() async throws {
        switch self.transport {
        case .stdio:
            try await self.startStdioServer()
        case .http:
            #if MCPHTTPSupport
            try await self.startHttpServer()
            #else
            fatalError("You must enable the MCPHTTPServer trait in Package.swift to support MCP HTTP Servers")
            #endif
        }
    }
}
