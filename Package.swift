// swift-tools-version:6.2
import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "AgentKit",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "ToolMacroClient", targets: ["ToolMacroClient"]),
        .executable(name: "ServerMacroClient", targets: ["ServerMacroClient"]),
        .library(name: "MCPServerKit", targets: ["MCPServerKit", "ToolMacro"]),
        .library(name: "MCPClientKit", targets: ["MCPClientKit"]),
        .library(name: "AgentKit", targets: ["AgentKit"]),
    ],
    traits: [
        "MCPHTTPSupport",
        .default(
            enabledTraits: [
                "MCPHTTPSupport"
            ]
        ),
    ],
    dependencies: [
        // to support macros implementation
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.1"),

        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.8.0"),

        // .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", branch: "main"),
        // https://github.com/modelcontextprotocol/swift-sdk/issues/110
        .package(url: "https://github.com/stallent/swift-sdk.git", branch: "streamable_server"),
        .package(url: "https://github.com/orlandos-nl/SSEKit.git", from: "1.1.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),

        .package(path: "../swift-bedrock-library"),
    ],
    targets: [
        .target(
            name: "AgentKit",
            dependencies: [
                .product(name: "BedrockService", package: "swift-bedrock-library"),
                "ToolMacro", "MCPServerKit", "MCPClientKit",
            ],
            path: "Sources/AgentKit"
        ),
        .executableTarget(
            name: "ServerMacroClient",
            dependencies: [
                .target(name: "MCPServerKit")
            ],
            path: "Sources/Macro/ServerMacroClient"
        ),
        .executableTarget(
            name: "ToolMacroClient",
            dependencies: [
                .target(name: "MCPServerKit")
            ],
            path: "Sources/Macro/ToolMacroClient"
        ),
        .target(
            name: "MCPServerKit",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
                .product(
                    name: "Hummingbird",
                    package: "hummingbird",
                    condition: .when(traits: ["MCPHTTPSupport"])
                ),
                .product(
                    name: "SSEKit",
                    package: "SSEKit",
                    condition: .when(traits: ["MCPHTTPSupport"])
                ),
                "ServerShared",
                "ToolMacro",
                "ServerMacro",
            ],
            path: "Sources/MCPServerKit"
        ),
        .target(
            name: "MCPClientKit",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk")
            ],
            path: "Sources/MCPClientKit"
        ),
        .testTarget(
            name: "MCPServerTests",
            dependencies: [
                .target(name: "MCPServerKit")
            ]
        ),

        // shared types and protocols for the schema macro system
        .target(
            name: "ToolShared",
            dependencies: [],
            path: "Sources/Macro/ToolShared"
        ),

        // shared types and protocols for the server macro system
        .target(
            name: "ServerShared",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk")
            ],
            path: "Sources/ServerShared"
        ),

        // a macro to generate JSON Schema based on DocC comments
        .macro(
            name: "ToolMacroImplementation",
            dependencies: [
                "ToolShared",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ],
            path: "Sources/Macro/ToolMacroImplementation"
        ),

        // a library that exposes the macro to users
        // TODO : should we make this a trait (enable by default and user can opt-out) ?
        .target(
            name: "ToolMacro",
            dependencies: [
                "ServerShared",
                "ToolShared",
                "ToolMacroImplementation",
            ],
            path: "Sources/Macro/ToolMacro"
        ),

        // Tests for the macro implementation
        .testTarget(
            name: "ToolMacroTests",
            dependencies: [
                "ToolShared",
                "ToolMacro",
                "ToolMacroImplementation",
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ]
        ),

        // A macro to simplifying writing MCPServers
        .macro(
            name: "ServerMacroImplementation",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                "ServerShared",
            ],
            path: "Sources/Macro/ServerMacroImplementation"
        ),
        // a library that exposes the macro to users
        .target(
            name: "ServerMacro",
            dependencies: [
                "ServerShared",
                "ServerMacroImplementation",
            ],
            path: "Sources/Macro/ServerMacro"
        ),
    ]
)
