import BedrockService
import Foundation
import Logging

public struct Agent {

    public let model: BedrockModel
    public let systemPrompt: String

    private let bedrock: BedrockService
    internal let logger: Logger

    public enum AuthenticationMethod {
        case tempCredentials(String)
        case profile(String)
        case sso(String?)
        case `default`
    }

    public init(
        systemPrompt: String = "",
        model: BedrockModel = .claude_sonnet_v4,
        auth: AuthenticationMethod = .default,
        region: String = "us-east-1",
        logger: Logger? = nil
    )
        async throws
    {

        self.systemPrompt = systemPrompt
        self.model = model

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
            region: Region(rawValue: region),
            // logger: logger,
            authentication: bedrockAuth
        )

        // let mcpFileLocationURL = URL(
        //     fileURLWithPath:
        //         "/Users/stormacq/Documents/amazon/code/swift/bedrock/mcp_music_tools"
        // )

        // let mcpTools: [MCPClient] = try await [MCPClient].create(
        //     from: mcpFileLocationURL,
        //     logger: logger
        // )

        // let tools = try await mcpTools.listTools().joined(separator: "\n")
        // logger.trace("Tools discovered:\n\(tools)")

    }

    // Enable callable syntax: agent("Hello!")
    public func callAsFunction(_ message: String) async throws {
        try await self.runLoop(
            initialPrompt: message,
            systemPrompt: self.systemPrompt,
            bedrock: self.bedrock,
            model: self.model,
            logger: self.logger
        )
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
