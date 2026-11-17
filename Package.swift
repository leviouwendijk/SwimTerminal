// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "SwimTerminal",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "swimtermregression",
            targets: ["SwimTerminalRegressionTests"]
        ),
        .library(
            name: "SwimTerminal",
            targets: ["SwimTerminal"]
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
        .package(
            url: "https://github.com/leviouwendijk/Clipboard.git",
            branch: "master"
        ),
    ],
    targets: [
        .executableTarget(
            name: "SwimTerminalRegressionTests",
            dependencies: ["SwimTerminal", "Terminal", .product(name: "Testing", package: "Testing")],
            path: "Tests/SwimTerminalRegressionTests"
        ),
        .target(
            name: "SwimTerminal",
            dependencies: [
                "Swim",
                "SwimInterpreter",
                "Terminal",
                "Clipboard",
            ]
        ),
        .executableTarget(
            name: "SwimTerminalTestFlows",
            dependencies: [
                "SwimTerminal",
                "Swim",
                "SwimInterpreter",
                "Terminal",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
