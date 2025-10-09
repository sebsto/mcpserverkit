import Testing
import Foundation
@testable import MCPClientKit

@Suite("MCP Configuration Tests")
struct MCPServerConfigurationTests {
    
    @Test("Decode MCP configuration from JSON")
    func testDecodeConfiguration() throws {
        let jsonData = try loadTestFixture()
        let config = try JSONDecoder().decode(MCPServerConfiguration.self, from: jsonData)
        
        #expect(config.mcpServers.count == 2)
        
        // Test HTTP configuration
        guard case .http(let httpConfig) = config.mcpServers["default-server"] else {
            throw TestError.unexpectedConfigurationType
        }
        #expect(httpConfig.url == "http://127.0.0.1:8080/mcp")
        #expect(httpConfig.disabled == false)
        #expect(httpConfig.timeout == 60000)
        
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
        let httpConfig = MCPServerConfiguration.ServerConfigurationStreamable(
            url: "http://localhost:3000/mcp",
            disabled: false,
            timeout: 60000
        )
        
        let stdioConfig = MCPServerConfiguration.ServerConfigurationStdio(
            command: "node",
            args: ["build/index.js", "--debug"],
            env: ["API_KEY": "your-api-key", "DEBUG": "true"],
            disabled: false,
            timeout: 60000
        )
        
        let config = MCPServerConfiguration(mcpServers: [
            "default-server": .http(httpConfig),
            "another-server": .stdio(stdioConfig)
        ])
        
        let encodedData = try JSONEncoder().encode(config)
        let decodedConfig = try JSONDecoder().decode(MCPServerConfiguration.self, from: encodedData)
        
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