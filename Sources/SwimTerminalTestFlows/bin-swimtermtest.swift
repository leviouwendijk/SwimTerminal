import SwimTerminal

@main
enum SwimTerminalTest {
    static func main() throws {
        switch CommandLine.arguments.dropFirst().first {
        case nil:
            try SwimTerminalBridgeSmoke.run()
            try SwimTerminalSurfaceSmoke.run()
            try SwimTerminalFollowEndSmoke.run()

            print(
                "swim terminal smoke passed"
            )

        case "surface":
            try SwimTerminalSurfaceLab.run()

        default:
            print(
                """
                swimtermtest

                Usage:
                    swift run swimtermtest
                    swift run swimtermtest surface

                Commands:
                    surface    Run the interactive SwimTerminal editor surface laboratory.
                """
            )
        }
    }
}
