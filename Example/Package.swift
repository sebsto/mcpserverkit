// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "MCPExampleServer",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "MCPExampleServer", targets: ["MCPExampleServer"])
    ],
    dependencies: [
        .package(name: "AgentKit", path: "..")  // Reference to the parent MCPServerKit package
    ],
    targets: [
        .executableTarget(
            name: "MCPExampleServer",
            dependencies: [
                .product(name: "AgentKit", package: "AgentKit")
            ],
            path: "Sources/Server"
        )
    ]
)
