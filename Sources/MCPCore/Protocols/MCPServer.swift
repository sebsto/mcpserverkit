import Foundation
import Vapor

/// Protocol defining the MCP server functionality
@preconcurrency
public protocol MCPServer: Sendable {
    /// The name of the MCP server
    var name: String { get }
    
    /// Register a tool with the server
    @discardableResult
    func registerTool(name: String, description: String, handler: @escaping MCPToolHandler) async -> Self
    
    /// Get all registered tools
    func getTools() async -> [String: MCPToolHandler]
    
    /// Run the server
    func run() async throws
}

/// Type for tool handler functions
public typealias MCPToolHandler = @Sendable (MCPContext, [String: Any]) async throws -> String

/// Implementation of the MCP server using Vapor
public actor VaporMCPServer: MCPServer {
    public nonisolated let name: String
    private var tools: [String: MCPToolHandler] = [:]
    private let app: Application
    
    public init(name: String) async throws {
        self.name = name
        self.app = try await Application.make(.development)
        
        // Configure routes
        setupRoutes()
    }
    
    deinit {
        app.shutdown()
    }
    
    private func setupRoutes() {
        // Setup MCP protocol routes
        app.post("mcp", "v1", "tools") { [weak self] req async -> MCPToolsResponse in
            guard let self = self else {
                return MCPToolsResponse(tools: [])
            }
            
            let toolsSnapshot = await self.getTools()
            let toolsList = toolsSnapshot.map { (name, _) in
                // In a real implementation, we would extract parameter information
                // from function signatures or annotations
                MCPTool(
                    name: name,
                    description: "Tool: \(name)",
                    parameters: [:]
                )
            }
            return MCPToolsResponse(tools: toolsList)
        }
        
        app.post("mcp", "v1", "call") { [weak self] req async throws -> MCPToolCallResponse in
            guard let self = self else {
                throw Abort(.internalServerError, reason: "Server instance not available")
            }
            
            let callRequest = try req.content.decode(MCPToolCallRequest.self)
            
            // Get the handler from the actor
            let handler = await self.getHandler(for: callRequest.name)
            
            guard let handler = handler else {
                throw Abort(.notFound, reason: "Tool not found: \(callRequest.name)")
            }
            
            let context = MCPContext()
            
            // Convert AnyCodable arguments to their unwrapped values
            let arguments = callRequest.arguments.mapValues { $0.unwrapped }
            
            let result = try await handler(context, arguments)
            
            return MCPToolCallResponse(result: result)
        }
    }
    
    // Helper method to safely get a handler for a tool name
    private func getHandler(for name: String) async -> MCPToolHandler? {
        return tools[name]
    }
    
    // Implementation of MCPServer protocol
    public func getTools() async -> [String: MCPToolHandler] {
        return tools
    }
    
    @discardableResult
    public func registerTool(name: String, description: String, handler: @escaping MCPToolHandler) async -> Self {
        tools[name] = handler
        return self
    }
    
    public func run() async throws {
        // Create a task that runs the Vapor application
        let task = Task {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                do {
                    try self.app.run()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        
        // Wait for the task to complete or be cancelled
        try await task.value
    }
}
