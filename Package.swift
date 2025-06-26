import CompilerPluginSupport
// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "MCPSwift",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "MCPExample", targets: ["MCPExample"]),
        .executable(name: "ToolMacroClient", targets: ["ToolMacroClient"]),
        .library(name: "MCPServerKit", targets: ["MCPServerKit", "ToolMacro"]),
        .library(name: "MCPClientKit", targets: ["MCPClientKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.1"),
        .package(path: "../swift-sdk"),
        // .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", branch: "main")
    ],
    targets: [
        //TODO: should be moved to an Examples directory
        .executableTarget(
            name: "MCPExample",
            dependencies: [
                .target(name: "MCPServerKit")
            ],
            path: "Sources/Example"
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
                "ToolMacro",
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
    ]
)
