// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "MCPSwift",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "MCPWeatherServer", targets: ["MCPWeatherServer"]),
        .library(name: "MCPServerKit", targets: ["MCPServerKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.7.0"),
    ],
    targets: [
        .executableTarget(
            name: "MCPWeatherServer",
            dependencies: [
                .target(name: "MCPServerKit"),
            ],
            path: "Sources/MCPWeatherServer"
        ),
        .target(
            name: "MCPServerKit",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
            ],
            path: "Sources/MCPServerKit"
        ),
        .testTarget(
            name: "MCPServerTests",
            dependencies: [
                .target(name: "MCPServerKit"),
            ]
        )
    ]
)
