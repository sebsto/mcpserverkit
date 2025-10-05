#if MCPHTTPSupport
import Hummingbird
import MCP
import ServiceLifecycle
import Logging

extension MCPServer {
    public func startHttpServer() async throws {
        // Register MCP handlers
        if let tools, tools.count > 0 {
            await registerTools(server, tools: tools)
        }
        if let prompts, prompts.count > 0 {
            await registerPrompts(server, prompts: prompts)
        }
        if let resources, !resources.resources.isEmpty {
            await registerResources(server, resources: resources)
        }

        // Create router and add routes
        let router = Router()
        router.get("hello") { request, _ -> String in
            "Hello"
        }

        // Create Hummingbird application
        let app = Application(
            router: router,
            configuration: .init(address: .hostname("127.0.0.1", port: 8080)),
            logger: self.logger
        )

        // Create service group with the MCPServer and the HTTP server
        let serviceGroup = ServiceGroup(
            configuration: .init(
                services: [app],
                gracefulShutdownSignals: [.sigterm, .sigint],
                logger: self.logger
            )
        )
        try await serviceGroup.run()
    }
}
#endif
