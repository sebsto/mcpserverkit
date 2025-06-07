// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "MCPSwift",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "MCPExampleServer", targets: ["MCPExampleServer"]),
        .library(name: "MCPServerKit", targets: ["MCPServerKit"]),
        .library(name: "MCPClientKit", targets: ["MCPClientKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "MCPExampleServer",
            dependencies: [
                .target(name: "MCPServerKit")
            ],
            path: "Sources/MCPExampleServer"
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
    ]
)
