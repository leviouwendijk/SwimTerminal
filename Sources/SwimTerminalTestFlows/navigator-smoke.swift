import SwimTerminal
import Terminal

enum SwimTerminalNavigatorSmoke {
    struct Failure:
        Error,
        CustomStringConvertible
    {
        var description: String
    }

    static func run() throws {
        var navigator = SwimTerminalNavigator()

        try expect(navigator.handle(.char("2")), .pending, "2")
        try expect(navigator.handle(.char("3")), .pending, "23")
        try check(navigator.pendingText == "23", "pending text 23")
        try expect(navigator.handle(.char("j")), .command(.vertical(23)), "23j")
        try check(navigator.pendingText == nil, "count consumed")

        try expect(navigator.handle(.char("k")), .command(.vertical(-1)), "k")
        try expect(navigator.handle(.char("4")), .pending, "4")
        try expect(navigator.handle(.char("h")), .command(.horizontal(-4)), "4h")

        try expect(navigator.handle(.char("g")), .pending, "g")
        try expect(navigator.handle(.char("g")), .command(.first), "gg")
        try expect(navigator.handle(.char("G")), .command(.last), "G")
        _ = navigator.handle(.char("1"))
        _ = navigator.handle(.char("2"))
        try expect(navigator.handle(.char("G")), .command(.position(11)), "12G is zero-based 11")

        try expect(navigator.handle(.control("D")), .command(.halfPage(1)), "ctrl-d")
        try expect(
            navigator.handle(TerminalKeyStroke(key: .char("u"), modifiers: .control)),
            .command(.halfPage(-1)),
            "ctrl-u as a modified stroke"
        )

        try expect(navigator.handle(.down), .unhandled(.down), "arrows stay with the view")
        try expect(navigator.handle(.char("y")), .unhandled(.char("y")), "y passes")
        _ = navigator.handle(.char("5"))
        try expect(navigator.handle(.escape), .cancelled, "escape cancels count")
        try expect(navigator.handle(.escape), .unhandled(.escape), "escape passes when idle")

        _ = navigator.handle(.char("9"))
        navigator.reset()
        try check(!navigator.isPending, "reset clears")

        print(
            "swim terminal navigator smoke passed"
        )
    }

    private static func expect(
        _ actual: SwimTerminalNavigatorResult,
        _ expected: SwimTerminalNavigatorResult,
        _ probe: String
    ) throws {
        guard actual == expected else {
            throw Failure(
                description: "\(probe): expected \(expected), got \(actual)"
            )
        }
    }

    private static func check(
        _ condition: Bool,
        _ probe: String
    ) throws {
        guard condition else {
            throw Failure(
                description: probe
            )
        }
    }
}
