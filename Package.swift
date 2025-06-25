// swift-tools-version:6.1
import PackageDescription
import CompilerPluginSupport


let package = Package(
    name: "MCPSwift",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "MCPExample", targets: ["MCPExample"]),
        .executable(name: "DocSchemaMacroClient", targets: ["DocSchemaMacroClient"]),
        .library(name: "MCPServerKit", targets: ["MCPServerKit"]),
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
                .target(name: "MCPServerKit"),
                .target(name: "DocSchemaMacro")
            ],
            path: "Sources/Example"
        ),
        .executableTarget(
            name: "DocSchemaMacroClient",
            dependencies: [
                .target(name: "MCPServerKit"),
                .target(name: "DocSchemaMacro")
            ],
            path: "Sources/Macro/DocSchemaMacroClient"
        ),
        .target(
            name: "MCPServerKit",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk")
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
            name: "DocSchemaShared",
            dependencies: [],
            path: "Sources/Macro/DocSchemaShared"
        ),

        // a macro to generate JSON Schema based on DocC comments
        .macro(
            name: "DocSchemaMacroImplementation",
            dependencies: [
                "DocSchemaShared",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ],
            path: "Sources/Macro/DocSchemaMacroImplementation"
        ),
        
        // a library that exposes the macro to users
        .target(
            name: "DocSchemaMacro",
            dependencies: [
                "DocSchemaShared",
                "DocSchemaMacroImplementation",
            ],
            path: "Sources/Macro/DocSchemaMacro"
        ),

        // Tests for the macro implementation
        .testTarget(
            name: "DocSchemaMacroTests",
            dependencies: [
                "DocSchemaShared",
                "DocSchemaMacro", 
                "DocSchemaMacroImplementation",
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ]
        ),
    ]
)
