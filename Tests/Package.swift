// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "SwimTerminalTests",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "swimtermregression",
            targets: ["SwimTerminalRegressionTests"]
        ),

        .executable(
            name: "swimtermtest",
            targets: ["SwimTerminalTestFlows"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/leviouwendijk/Testing.git", branch: "master"),
        .package(
            url: "https://github.com/leviouwendijk/Swim.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/SwimInterpreter.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Terminal.git",
            branch: "master"
        ),
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "SwimTerminalRegressionTests",
            dependencies: [.product(name: "SwimTerminal", package: "SwimTerminal"), "Terminal", .product(name: "Testing", package: "Testing")]
        ),
        .executableTarget(
            name: "SwimTerminalTestFlows",
            dependencies: [
                .product(name: "SwimTerminal", package: "SwimTerminal"),
                "Swim",
                "SwimInterpreter",
                "Terminal",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
