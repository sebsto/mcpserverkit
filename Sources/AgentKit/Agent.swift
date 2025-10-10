import BedrockService
import Logging
import MCPServerKit

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A high-level AI agent that provides conversational capabilities using Amazon Bedrock.
///
/// The Agent struct simplifies interaction with Bedrock models by providing a callable interface
/// and handling authentication, model configuration, and conversation flow.
public actor Agent: Sendable {

    /// The Bedrock model used for generating responses.
    public let model: BedrockModel
    /// The system prompt that defines the agent's behavior and context.
    public let systemPrompt: String
    /// the list of tools this agent can use to answer questions
    public let tools: [any ToolProtocol]
    /// the history of messages
    public var messages: History

    private let bedrock: BedrockService
    internal let logger: Logger

    /// Creates a new Agent instance with the specified configuration.
    ///
    /// - Parameters:
    ///   - systemPrompt: The system prompt to guide the agent's behavior. Defaults to empty string.
    ///   - model: The Bedrock model to use. Defaults to Claude Sonnet v4.
    ///   - tools: The tools this agent can use to answer questions
    ///   - auth: The authentication method. Defaults to default credential chain.
    ///   - region: The AWS region to use. Defaults to us-east-1.
    ///   - logger: Optional custom logger. If nil, creates a default logger.
    /// - Throws: An error if authentication fails or the Bedrock service cannot be initialized.
    @discardableResult
    public init(
        _ initialPrompt: String = "",
        systemPrompt: String = "",
        model: BedrockModel = .claude_sonnet_v4,
        messages: History = [],
        tools: [any ToolProtocol] = [],
        mcpTools: [MCPClient] = [],
        auth: AuthenticationMethod = .default,
        region: Region = .useast1,
        logger: Logger? = nil,
        callback: AgentCallbackFunction? = nil
    )
        async throws
    {

        self.systemPrompt = systemPrompt
        self.messages = messages
        self.model = model
        
        // our local tools
        let localTools = tools
        
        // our remote tools (MCP)
        var remoteTools: [any ToolProtocol] = []
        for mcpClient in mcpTools { 
            await remoteTools.append(contentsOf: mcpClient.asTools())
        }

        // create our bag of tools by combining the local and remote tools
        self.tools = localTools + remoteTools

        var logger = logger ?? Logger(label: "AgentKit")
        logger.logLevel =
            ProcessInfo.processInfo.environment["LOG_LEVEL"].flatMap {
                Logger.Level(rawValue: $0)
            } ?? .info
        self.logger = logger

        let bedrockAuth: BedrockAuthentication
        switch auth {
        case .tempCredentials(let path):
            logger.warning(
                "Using temporary credentials file",
                metadata: ["path": .string(path)]
            )
            let tempCredentials = try Self.loadAWSCredentials(fromFile: path)
            bedrockAuth = .static(
                accessKey: tempCredentials.accessKeyId,
                secretKey: tempCredentials.secretAccessKey,
                sessionToken: tempCredentials.sessionToken
            )
        case .sso(let profileName):
            bedrockAuth = .sso(profileName: profileName ?? "default")
        case .profile(let profileName):
            bedrockAuth = .profile(profileName: profileName)
        default:
            bedrockAuth = .default
        }

        self.bedrock = try await BedrockService(
            region: region,
            logger: logger,
            authentication: bedrockAuth
        )

        if initialPrompt != "" {
            try await self.runLoop(
                prompt: initialPrompt,
                systemPrompt: systemPrompt,
                bedrock: bedrock,
                model: model,
                tools: tools,
                logger: logger,
                callback: callback
            )
        }

    }

    /// Sends a message to the agent and processes the response.
    ///
    /// This method enables callable syntax, allowing you to use the agent like a function:
    /// ```swift
    /// let agent = try await Agent()
    /// try await agent("Hello, how are you?")
    /// ```
    ///
    /// - Parameters:
    ///   - message: The message to send to the agent.
    ///   - callback: Optional callback function to handle events during processing.
    /// - Throws: An error if the conversation fails or the model is not supported.
    public func callAsFunction(_ message: String, callback: AgentCallbackFunction? = nil) async throws {
        try await self.runLoop(
            prompt: message,
            systemPrompt: self.systemPrompt,
            bedrock: self.bedrock,
            model: self.model,
            tools: self.tools,
            logger: self.logger,
            callback: callback
        )
    }

    /// Authentication methods supported by the agent.
    public enum AuthenticationMethod {
        /// Use temporary credentials from a file path.
        case tempCredentials(String)
        /// Use a named AWS profile.
        case profile(String)
        /// Use AWS SSO with optional profile name.
        case sso(String?)
        /// Use default AWS credential chain.
        case `default`
    }

    private enum CredentialsError: Error {
        case fileNotFound(String)
        case invalidData(String)
        case decodingError(Error)
        case credentialsExpired(Date, Date)  // Includes expiration date and current date for context
    }
    private static func loadAWSCredentials(fromFile path: String) throws -> AWSTemporaryCredentials {
        let fileManager = FileManager.default

        // Check if file exists
        guard fileManager.fileExists(atPath: path) else {
            throw CredentialsError.fileNotFound("Credentials file not found at path: \(path)")
        }

        // Read file data
        guard let data = fileManager.contents(atPath: path) else {
            throw CredentialsError.invalidData("Could not read data from file: \(path)")
        }

        // Decode JSON into AWSTemporaryCredentials
        let credentials: AWSTemporaryCredentials
        do {
            let decoder = JSONDecoder()
            credentials = try decoder.decode(AWSTemporaryCredentials.self, from: data)
        } catch {
            throw CredentialsError.decodingError(error)
        }
        // Verify credentials haven't expired
        let currentDate = Date()
        if currentDate >= credentials.expiration {
            throw CredentialsError.credentialsExpired(credentials.expiration, currentDate)
        }
        return credentials
    }
}
