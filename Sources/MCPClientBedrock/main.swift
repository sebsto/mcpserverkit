import Foundation
import ArgumentParser
import AsyncHTTPClient
import SotoBedrock
import SotoCore
import MCPCore

struct MCPClientBedrock: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mcp-client-bedrock",
        abstract: "MCP Client for Amazon Bedrock",
        subcommands: [],
        defaultSubcommand: nil
    )
    
    @Option(name: .long, help: "AWS region to use")
    var region = ProcessInfo.processInfo.environment["AWS_REGION"] ?? "us-east-1"
    
    @Option(name: .long, help: "Bedrock model ID to use")
    var modelId = "us.anthropic.claude-3-7-sonnet-20250219-v1:0"
    
    @Option(name: .long, help: "System prompt for the model")
    var systemPrompt = "You are a helpful AI assistant. Use the AWS Lambda tools to improve your answers."
    
    @Option(name: .long, help: "MCP server URL")
    var mcpServerUrl = "http://localhost:8080"
    
    mutating func run() async throws {
        print("Starting MCP Client for Amazon Bedrock")
        print("Model ID: \(modelId)")
        
        // Create AWS client
        let awsClient = AWSClient(credentialProvider: .default, httpClientProvider: .createNew)
        let bedrockClient = Bedrock(client: awsClient, region: .init(rawValue: region))
        
        // Create HTTP client for MCP server
        let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
        
        // Create MCP client
        let mcpClient = try MCPBedrockClient(
            bedrockClient: bedrockClient,
            httpClient: httpClient,
            modelId: modelId,
            systemPrompt: systemPrompt,
            mcpServerUrl: mcpServerUrl
        )
        
        // Start conversation loop
        try await runConversation(client: mcpClient)
        
        // Cleanup
        try await httpClient.shutdown()
        try await awsClient.shutdown()
    }
    
    func runConversation(client: MCPBedrockClient) async throws {
        print("\nWelcome to the MCP Bedrock Client!")
        print("Type 'exit' to quit.\n")
        
        var conversationId: String? = nil
        
        while true {
            print("\nYou: ", terminator: "")
            guard let input = readLine(), !input.isEmpty else { continue }
            
            if input.lowercased() == "exit" {
                break
            }
            
            do {
                let response = try await client.sendMessage(input, conversationId: conversationId)
                conversationId = response.conversationId
                
                print("\nAssistant: \(response.message)")
            } catch {
                print("\nError: \(error)")
            }
        }
    }
}

actor MCPBedrockClient {
    private let bedrockClient: Bedrock
    private let httpClient: HTTPClient
    private let modelId: String
    private let systemPrompt: String
    private let mcpServerUrl: String
    
    init(bedrockClient: Bedrock, httpClient: HTTPClient, modelId: String, systemPrompt: String, mcpServerUrl: String) {
        self.bedrockClient = bedrockClient
        self.httpClient = httpClient
        self.modelId = modelId
        self.systemPrompt = systemPrompt
        self.mcpServerUrl = mcpServerUrl
    }
    
    struct ConversationResponse {
        let conversationId: String
        let message: String
    }
    
    func sendMessage(_ message: String, conversationId: String? = nil) async throws -> ConversationResponse {
        // Fetch available tools from MCP server
        let tools = try await fetchAvailableTools()
        
        // Create Bedrock Converse request
        var request = Bedrock.ConverseRequest(
            modelId: modelId,
            messages: [
                .init(role: "user", content: message)
            ]
        )
        
        // Add system message if this is a new conversation
        if conversationId == nil {
            request.messages.insert(.init(role: "system", content: systemPrompt), at: 0)
        }
        
        // Add conversation ID if continuing a conversation
        if let conversationId = conversationId {
            request.conversationId = conversationId
        }
        
        // Add tools configuration
        request.toolConfig = .init(
            tools: tools.map { tool in
                Bedrock.ToolDefinition(
                    name: tool.name,
                    description: tool.description,
                    inputSchema: .init(
                        type: "object",
                        properties: tool.parameters.mapValues { param in
                            Bedrock.SchemaProperty(
                                type: param.type,
                                description: param.description
                            )
                        },
                        required: tool.parameters.filter { $0.value.required }.map { $0.key }
                    )
                )
            }
        )
        
        // Send request to Bedrock
        let response = try await bedrockClient.converse(request)
        
        // Handle tool calls if needed
        var finalResponse = response
        if let toolUse = response.output?.toolUses?.first {
            let toolResult = try await callTool(name: toolUse.name, arguments: toolUse.input)
            
            // Create a follow-up request with the tool result
            var followUpRequest = Bedrock.ConverseRequest(
                modelId: modelId,
                messages: request.messages
            )
            
            // Add the assistant's response with tool use
            followUpRequest.messages.append(.init(
                role: "assistant",
                content: response.output?.message ?? "",
                toolUses: response.output?.toolUses
            ))
            
            // Add the tool result
            followUpRequest.messages.append(.init(
                role: "tool",
                content: toolResult,
                toolUseId: toolUse.id
            ))
            
            // Set conversation ID
            followUpRequest.conversationId = response.conversationId
            
            // Send follow-up request
            finalResponse = try await bedrockClient.converse(followUpRequest)
        }
        
        return ConversationResponse(
            conversationId: finalResponse.conversationId ?? "",
            message: finalResponse.output?.message ?? "No response"
        )
    }
    
    private func fetchAvailableTools() async throws -> [MCPTool] {
        let url = URL(string: "\(mcpServerUrl)/mcp/v1/tools")!
        var request = HTTPClientRequest(url: url.absoluteString)
        request.method = .POST
        
        let response = try await httpClient.execute(request)
        
        guard response.status == .ok else {
            throw NSError(domain: "MCPClient", code: Int(response.status.code), userInfo: [
                NSLocalizedDescriptionKey: "Failed to fetch tools: HTTP \(response.status.code)"
            ])
        }
        
        var body = ByteBuffer()
        for try await buffer in response.body {
            body.writeBuffer(&buffer)
        }
        
        let toolsResponse = try JSONDecoder().decode(MCPToolsResponse.self, from: body)
        
        return toolsResponse.tools
    }
    
    private func callTool(name: String, arguments: [String: Any]) async throws -> String {
        let url = URL(string: "\(mcpServerUrl)/mcp/v1/call")!
        var request = HTTPClientRequest(url: url.absoluteString)
        request.method = .POST
        request.headers.add(name: "Content-Type", value: "application/json")
        
        // Create request body
        let requestBody: [String: Any] = [
            "name": name,
            "arguments": arguments
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        request.body = .bytes(ByteBuffer(data: jsonData))
        
        let response = try await httpClient.execute(request)
        
        guard response.status == .ok else {
            throw NSError(domain: "MCPClient", code: Int(response.status.code), userInfo: [
                NSLocalizedDescriptionKey: "Failed to call tool: HTTP \(response.status.code)"
            ])
        }
        
        var body = ByteBuffer()
        for try await buffer in response.body {
            body.writeBuffer(&buffer)
        }
        
        let toolResponse = try JSONDecoder().decode(MCPToolCallResponse.self, from: body)
        
        return toolResponse.result
    }
}

// Run the command
@main
struct MCPClientBedrockMain {
    static func main() async {
        await MCPClientBedrock.main()
    }
}
