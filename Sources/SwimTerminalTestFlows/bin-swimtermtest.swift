import SwimTerminal

@main
enum SwimTerminalTest {
    static func main() throws {
        switch CommandLine.arguments.dropFirst().first {
        case nil:
            try SwimTerminalBridgeSmoke.run()
            try SwimTerminalSurfaceSmoke.run()
            try SwimTerminalFollowEndSmoke.run()
            try SwimTerminalRejectionSmoke.run()

            print(
                "swim terminal smoke passed"
            )

        case "surface":
            try SwimTerminalSurfaceLab.run()

        case "nonmod":
            try SwimTerminalSurfaceLab.runNonmodifiable()

        default:
            print(
                """
                swimtermtest

                Usage:
                    swift run swimtermtest
                    swift run swimtermtest surface
                    swift run swimtermtest nonmod

                Commands:
                    surface    Run the interactive editable SwimTerminal surface laboratory.
                    nonmod     Run the interactive nonmodifiable SwimTerminal buffer laboratory.
                """
            )
        }
    }
}
