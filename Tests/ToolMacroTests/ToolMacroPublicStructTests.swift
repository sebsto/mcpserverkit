#if MCPMacros

import Testing
import ToolMacro
import MCPServerKit

// Test structs at file scope to allow public/package modifiers
@Tool(name: "public-test", description: "Public test tool")
public struct PublicTestTool {
    typealias Input = String
    typealias Output = String

    /// Handle test input
    /// - Parameter input: Test input string
    func handle(input: String) async throws -> String {
        "Public: \(input)"
    }
}

@Tool(name: "package-test", description: "Package test tool")
package struct PackageTestTool {
    typealias Input = String
    typealias Output = String

    /// Handle test input
    /// - Parameter input: Test input string
    func handle(input: String) async throws -> String {
        "Package: \(input)"
    }
}

@Tool(name: "internal-test", description: "Internal test tool")
struct InternalTestTool {
    typealias Input = String
    typealias Output = String

    /// Handle test input
    /// - Parameter input: Test input string
    func handle(input: String) async throws -> String {
        "Internal: \(input)"
    }
}

@Suite("Tool Macro Access Level Tests")
struct ToolMacroAccessLevelTests {

    @Test("Public struct with @Tool macro compiles successfully")
    func testPublicStructCompilation() throws {
        let tool = PublicTestTool()
        #expect(tool.toolName == "public-test")
        #expect(tool.toolDescription == "Public test tool")
        #expect(!tool.inputSchema.isEmpty)
    }

    @Test("Package struct with @Tool macro compiles successfully")
    func testPackageStructCompilation() throws {
        let tool = PackageTestTool()
        #expect(tool.toolName == "package-test")
        #expect(tool.toolDescription == "Package test tool")
        #expect(!tool.inputSchema.isEmpty)
    }

    @Test("Internal struct with @Tool macro compiles successfully")
    func testInternalStructCompilation() throws {
        let tool = InternalTestTool()
        #expect(tool.toolName == "internal-test")
        #expect(tool.toolDescription == "Internal test tool")
        #expect(!tool.inputSchema.isEmpty)
    }
}

#endif
