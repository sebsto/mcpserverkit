// swift-tools-version:6.1
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
        .package(name: "MCPServerKit", path: ".."),  // Reference to the parent MCPServerKit package
    ],
    targets: [
        .executableTarget(
            name: "MCPExampleServer",
            dependencies: [
                .product(name: "MCPServerKit", package: "MCPServerKit")
            ],
        )
    ]
)
