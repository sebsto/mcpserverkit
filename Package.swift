// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "MCP2Lambda",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "MCP2Lambda", targets: ["MCP2Lambda"]),
        .executable(name: "MCPClientBedrock", targets: ["MCPClientBedrock"]),
        .library(name: "MCPCore", targets: ["MCPCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/swift-server/async-http-client", from: "1.20.0"),
        .package(url: "https://github.com/vapor/vapor", from: "4.92.1"),
        .package(url: "https://github.com/soto-project/soto", from: "6.8.0"),
        .package(url: "https://github.com/apple/swift-testing", from: "0.6.0")
    ],
    targets: [
        .executableTarget(
            name: "MCP2Lambda",
            dependencies: [
                "MCPCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "SotoLambda", package: "soto")
            ],
            path: "Sources/MCP2Lambda"
        ),
        .executableTarget(
            name: "MCPClientBedrock",
            dependencies: [
                "MCPCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "SotoBedrock", package: "soto")
            ],
            path: "Sources/MCPClientBedrock"
        ),
        .target(
            name: "MCPCore",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ],
            path: "Sources/MCPCore"
        ),
        .testTarget(
            name: "MCP2LambdaTests",
            dependencies: [
                "MCP2Lambda", 
                "MCPCore",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Tests/MCP2LambdaTests"
        )
    ]
)
