import SwimTerminal

@main
enum SwimTerminalTest {
    static func main() throws {
        try SwimTerminalBridgeSmoke.run()
        try SwimTerminalSurfaceSmoke.run()

        print(
            "swim terminal smoke passed"
        )
    }
}
