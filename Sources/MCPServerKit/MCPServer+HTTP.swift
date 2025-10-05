#if MCPHTTPSupport
import HTTPTypes
import Hummingbird
import MCP
import ServiceLifecycle
import Logging
import Foundation

extension MCPServer {
    public func startHttpServer(port: Int = 8080) async throws {
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

        // Create router and add MCP endpoint
        let router = Router()

        router.addRoutes(
            StreamableMCPController(
                path: "mcp",
                stateful: false,
                jsonResponses: true,
                server: self.server,
                logger: logger
            ).endpoints
        )

        router.addMiddleware {
            // logging middleware
            LogRequestsMiddleware(.trace)
        }

        // Create Hummingbird application
        let app = Application(
            router: router,
            configuration: .init(address: .hostname("127.0.0.1", port: port)),
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
