// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WakeBee",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "WakeBee", targets: ["WakeBee"]),
               .executable(name: "WakeBeeHelper", targets: ["WakeBeeHelper"])],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0")
    ],
    targets: [
        .target(name: "WakeBeeCore"),
        .target(name: "WakeBeeHelperProtocol"),
        .executableTarget(name: "WakeBeeHelper", dependencies: ["WakeBeeCore", "WakeBeeHelperProtocol"]),
        .executableTarget(
            name: "WakeBee",
            dependencies: ["WakeBeeCore", "WakeBeeHelperProtocol", .product(name: "Sparkle", package: "Sparkle")],
            linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]
        ),
        .testTarget(name: "WakeBeeCoreTests", dependencies: ["WakeBeeCore"]),
        .testTarget(name: "WakeBeeTests", dependencies: ["WakeBee"])
    ]
)
