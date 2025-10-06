import MCP

/// Extension to MCPServer for working with resources
extension MCPServer {
    // /// Registers resources with the server
    // /// - Parameter registry: The resource registry to register
    // /// - Returns: The server, for chaining
    // @discardableResult
    // public func registerResources(_ registry: MCPResourceRegistry) -> Self {
    //     MCPServer(
    //         name: self.name,
    //         version: self.version,
    //         tools: self.tools,
    //         prompts: self.prompts,
    //         resources: registry
    //     )
    // }

    // /// Create a server with resources
    // /// - Parameters:
    // ///   - name: The server name
    // ///   - version: The server version
    // ///   - resources: The resources to register
    // /// - Returns: A new MCPServer instance
    // public static func create(
    //     name: String,
    //     version: String,
    //     resources: MCPResourceRegistry
    // ) -> MCPServer {
    //     create(name: name, version: version, tools: nil, prompts: nil, resources: resources)
    // }

    // /// Create a server with tools and resources
    // /// - Parameters:
    // ///   - name: The server name
    // ///   - version: The server version
    // ///   - tools: The tools to register
    // ///   - resources: The resources to register
    // /// - Returns: A new MCPServer instance
    // public static func create(
    //     name: String,
    //     version: String,
    //     tools: [any ToolProtocol],
    //     resources: MCPResourceRegistry
    // ) -> MCPServer {
    //     create(name: name, version: version, tools: tools, prompts: nil, resources: resources)
    // }

    // /// Create a server with prompts and resources
    // /// - Parameters:
    // ///   - name: The server name
    // ///   - version: The server version
    // ///   - prompts: The prompts to register
    // ///   - resources: The resources to register
    // /// - Returns: A new MCPServer instance
    // public static func create(
    //     name: String,
    //     version: String,
    //     prompts: [MCPPrompt],
    //     resources: MCPResourceRegistry
    // ) -> MCPServer {
    //     create(name: name, version: version, tools: nil, prompts: prompts, resources: resources)
    // }

    /// Register resources with the server
    package func registerResources(_ server: Server, resources: MCPResourceRegistry) async {
        // Register resources/list handler
        await server.withMethodHandler(ListResources.self) { id, params in
            let mcpResources = resources.asMCPResources()
            return ListResources.Result(resources: mcpResources, nextCursor: nil)
        }

        // Register resources/read handler
        await server.withMethodHandler(ReadResource.self) { id, params in
            // Find the resource with the requested URI
            guard let resource = resources.find(uri: params.uri) else {
                throw MCPServerError.resourceNotFound(params.uri)
            }

            // Return the resource content
            return ReadResource.Result(contents: [resource.content])
        }

        // Register resources/templates/list handler
        await server.withMethodHandler(ListResourceTemplates.self) { _, _ in
            // For now, we don't support resource templates
            ListResourceTemplates.Result(templates: [])
        }
    }
}
