import Testing
import Foundation
@testable import MCPClientKit

@Suite("MCP Configuration Tests")
struct MCPConfigurationTests {
    
    @Test("Decode MCP configuration from JSON")
    func testDecodeConfiguration() throws {
        let jsonData = try loadTestFixture()
        let config = try JSONDecoder().decode(MCPConfiguration.self, from: jsonData)
        
        #expect(config.mcpServers.count == 2)
        
        // Test HTTP configuration
        guard case .http(let httpConfig) = config.mcpServers["default-server"] else {
            throw TestError.unexpectedConfigurationType
        }
        #expect(httpConfig.type == "streamable-http")
        #expect(httpConfig.url == "http://localhost:3000/mcp")
        #expect(httpConfig.note == "For Streamable HTTP connections, add this URL directly in your MCP Client")
        
        // Test stdio configuration
        guard case .stdio(let stdioConfig) = config.mcpServers["another-server"] else {
            throw TestError.unexpectedConfigurationType
        }
        #expect(stdioConfig.command == "node")
        #expect(stdioConfig.args == ["build/index.js", "--debug"])
        #expect(stdioConfig.env?["API_KEY"] == "your-api-key")
        #expect(stdioConfig.env?["DEBUG"] == "true")
    }
    
    @Test("Encode MCP configuration to JSON")
    func testEncodeConfiguration() throws {
        let httpConfig = MCPConfiguration.ToolConfigurationStreamable(
            type: "streamable-http",
            url: "http://localhost:3000/mcp",
            note: "For Streamable HTTP connections, add this URL directly in your MCP Client"
        )
        
        let stdioConfig = MCPConfiguration.ToolConfigurationStdio(
            command: "node",
            args: ["build/index.js", "--debug"],
            env: ["API_KEY": "your-api-key", "DEBUG": "true"]
        )
        
        let config = MCPConfiguration(mcpServers: [
            "default-server": .http(httpConfig),
            "another-server": .stdio(stdioConfig)
        ])
        
        let encodedData = try JSONEncoder().encode(config)
        let decodedConfig = try JSONDecoder().decode(MCPConfiguration.self, from: encodedData)
        
        #expect(decodedConfig.mcpServers.count == 2)
        
        // Verify round-trip encoding/decoding works
        guard case .http(let decodedHttpConfig) = decodedConfig.mcpServers["default-server"] else {
            throw TestError.unexpectedConfigurationType
        }
        #expect(decodedHttpConfig.url == httpConfig.url)
        
        guard case .stdio(let decodedStdioConfig) = decodedConfig.mcpServers["another-server"] else {
            throw TestError.unexpectedConfigurationType
        }
        #expect(decodedStdioConfig.command == stdioConfig.command)
    }
    
    private func loadTestFixture() throws -> Data {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: "mcp-config", withExtension: "json") else {
            throw TestError.fixtureNotFound
        }
        return try Data(contentsOf: url)
    }
}

enum TestError: Error {
    case fixtureNotFound
    case unexpectedConfigurationType
}