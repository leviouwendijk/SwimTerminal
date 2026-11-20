// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "SwimTerminal",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "SwimTerminal",
            targets: ["SwimTerminal"]
        ),
    ],
    dependencies: [
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
        .target(
            name: "SwimTerminal",
            dependencies: [
                "Swim",
                "SwimInterpreter",
                "Terminal",
                "Clipboard",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
