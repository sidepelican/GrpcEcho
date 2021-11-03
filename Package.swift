// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "GrpcEcho",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/grpc/grpc-swift.git", .branch("1.4.1-async-await")),
    ],
    targets: [
        .executableTarget(
            name: "GrpcEcho",
            dependencies: [.product(name: "GRPC", package: "grpc-swift")]
        ),
    ]
)
