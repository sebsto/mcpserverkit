// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "MCPExampleServer",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "Server", targets: ["Server"]),
        .executable(name: "Client", targets: ["Client"]),
    ],
    dependencies: [
        .package(name: "AgentKit", path: "..")
    ],
    targets: [
        .executableTarget(
            name: "Server",
            dependencies: [
                .product(name: "AgentKit", package: "AgentKit")
            ],
            path: "Sources/Server"
        ),
        .executableTarget(
            name: "Client",
            dependencies: [
                .product(name: "AgentKit", package: "AgentKit")
            ],
            path: "Sources/Client"
        ),
    ]
)
