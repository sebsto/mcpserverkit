// #if MCPHTTPSupport
// import HTTPTypes
// import Hummingbird
// import MCP
// import ServiceLifecycle
// import Logging
// import Foundation

// // MARK: - Session Management

// actor SessionManager {
//     private var activeSessions: Set<String> = []

//     func createSession() -> String {
//         let sessionId = UUID().uuidString
//         activeSessions.insert(sessionId)
//         return sessionId
//     }

//     func isValidSession(_ sessionId: String) -> Bool {
//         activeSessions.contains(sessionId)
//     }

//     func terminateSession(_ sessionId: String) -> Bool {
//         activeSessions.remove(sessionId) != nil
//     }
// }

// extension MCPServer {
//     private static let sessionManager = SessionManager()

//     public func startHttpServer(port: Int = 8080) async throws {
//         // Register MCP handlers
//         if let tools, tools.count > 0 {
//             await registerTools(server, tools: tools)
//         }
//         if let prompts, prompts.count > 0 {
//             await registerPrompts(server, prompts: prompts)
//         }
//         if let resources, !resources.resources.isEmpty {
//             await registerResources(server, resources: resources)
//         }

//         // Create router and add MCP endpoint
//         let router = Router()

//         // MCP endpoint - handles both POST and GET
//         router.post("/mcp") { request, context in
//             try await self.handleMCPPost(request: request, context: context)
//         }

//         router.get("/mcp") { request, context in
//             try await self.handleMCPGet(request: request, context: context)
//         }

//         router.delete("/mcp") { request, context in
//             try await self.handleMCPDelete(request: request, context: context)
//         }

//         // Create Hummingbird application
//         let app = Application(
//             router: router,
//             configuration: .init(address: .hostname("127.0.0.1", port: port)),
//             logger: self.logger
//         )

//         // Create service group with the MCPServer and the HTTP server
//         let serviceGroup = ServiceGroup(
//             configuration: .init(
//                 services: [app],
//                 gracefulShutdownSignals: [.sigterm, .sigint],
//                 logger: self.logger
//             )
//         )
//         try await serviceGroup.run()
//     }

//     private func handleMCPPost(request: Request, context: any RequestContext) async throws -> Response {
//         // Validate Origin header for security
//         guard let origin = request.headers[.origin],
//             isValidOrigin(origin)
//         else {
//             return Response(status: .badRequest)
//         }

//         // Check protocol version
//         let protocolVersion = request.headers[.mcpProtocolVersion] ?? "2025-03-26"
//         guard isValidProtocolVersion(protocolVersion) else {
//             return Response(status: .badRequest)
//         }

//         let accepts = request.headers[HTTPField.Name.accept]
//         guard isValidAccept(accepts) else {
//             return Response(status: .notAcceptable)
//         }

//         // Get session ID if present
//         let sessionId = request.headers[.mcpSessionId]

//         // Validate session if required
//         if let sessionId = sessionId {
//             guard await isValidSession(sessionId) else {
//                 return Response(status: .notFound)
//             }
//         }

//         // Collect JSON-RPC message from body
//         let body = try await request.body.collect(upTo: .max)

//     }

//     // https://modelcontextprotocol.io/specification/2025-06-18/basic/transports#listening-for-messages-from-the-server
//     // GET = SSE
//     // not supported at the moment
//     private func handleMCPGet(request: Request, context: any RequestContext) async throws -> Response {
//         // Validate Origin header for security
//         guard let origin = request.headers[values: .origin].first,
//             isValidOrigin(origin)
//         else {
//             return Response(status: .badRequest)
//         }

//         // Check if client accepts SSE
//         let acceptHeader = request.headers[values: .accept].joined(separator: ", ")
//         guard acceptHeader.contains("text/event-stream") else {

//         }

//         // Get session ID if present
//         let sessionId = request.headers[values: .init("Mcp-Session-Id")!].first

//         // Validate session if required
//         if let sessionId = sessionId {
//             guard await isValidSession(sessionId) else {
//                 return Response(status: .notFound)
//             }
//         }

//         // SSE implementation would go here (not covered in this phase)
//         return Response(status: .methodNotAllowed)
//     }

//     private func handleMCPDelete(request: Request, context: any RequestContext) async throws -> Response {
//         // Handle session termination
//         guard let sessionId = request.headers[.mcpSessionId] else {
//             return Response(status: .badRequest)
//         }

//         if await terminateSession(sessionId) {
//             return Response(status: .ok)
//         } else {
//             return Response(status: .methodNotAllowed)
//         }
//     }

//     // MARK: - Helper Methods

//     private func isValidOrigin(_ origin: String) -> Bool {
//         // Basic origin validation - should be more sophisticated in production
//         origin.hasPrefix("http://localhost") || origin.hasPrefix("http://127.0.0.1") || origin.hasPrefix("https://")
//     }

//     private func isValidProtocolVersion(_ version: String) -> Bool {
//         ["2025-06-18", "2025-03-26", "2024-11-05"].contains(version)
//     }

//     private func isValidAccept(_ acceptHeader: String?) -> Bool {
//         (acceptHeader?.contains("application/json") ?? false) && (acceptHeader?.contains("text/event-stream") ?? false)
//     }

//     private func isValidSession(_ sessionId: String) async -> Bool {
//         await Self.sessionManager.isValidSession(sessionId)
//     }

//     private func terminateSession(_ sessionId: String) async -> Bool {
//         await Self.sessionManager.terminateSession(sessionId)
//     }

//     private func createSession() async -> String {
//         await Self.sessionManager.createSession()
//     }
// }

// extension HTTPField.Name {
//     private static let _mcpSessionId = HTTPField.Name("Mcp-Session-Id")
//     static var mcpSessionId: HTTPField.Name {
//         get {
//             guard let headerName = _mcpSessionId else {
//                 fatalError("Invalid \"Mcp-Session-Id\" HTTP Header name")
//             }
//             return headerName
//         }
//     }
//     private static let _mcpProtocolVersion = HTTPField.Name("MCP-Protocol-Version")
//     static var mcpProtocolVersion: HTTPField.Name {
//         get {
//             guard let headerName = _mcpProtocolVersion else {
//                 fatalError("Invalid \"Mcp-Protocol-Version\" HTTP Header name")
//             }
//             return headerName
//         }
//     }
// }
// #endif
