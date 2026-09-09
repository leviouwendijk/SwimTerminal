import SwimTerminal

@main
enum SwimTerminalTest {
    static func main() throws {
        try SwimTerminalBridgeSmoke.run()

        print(
            "swim terminal bridge smoke passed"
        )
    }
}
