import SwimInterpreter
import Terminal

public enum SwimTerminalNavigatorResult:
    Sendable,
    Hashable
{
    /// A count or `g` prefix is pending; show `SwimTerminalNavigator.pendingText`.
    case pending
    case command(TerminalNavigationCommand)
    /// Escape cancelled a pending sequence.
    case cancelled
    /// Not navigation; the view handles the key itself.
    case unhandled(TerminalKey)
}

/// Normal-mode navigation for views that are not editors: counts, `gg`, `G`,
/// `h j k l`, `ctrl-d ctrl-u ctrl-f ctrl-b`. Arrows, Home/End and PgUp/PgDn stay
/// with the view, which keeps its own meaning for them.
public struct SwimTerminalNavigator:
    Sendable,
    Hashable
{
    private var interpreter: NavigationInterpreter

    public init() {
        interpreter = NavigationInterpreter()
    }

    public var isPending: Bool {
        interpreter.isPending
    }

    public var pendingText: String? {
        interpreter.pendingText
    }

    /// Call on focus, view or mode changes so a count cannot leak.
    public mutating func reset() {
        interpreter.reset()
    }

    public mutating func handle(
        _ key: TerminalKey
    ) -> SwimTerminalNavigatorResult {
        handle(
            TerminalKeyStroke(
                key: key
            )
        )
    }

    public mutating func handle(
        _ keyStroke: TerminalKeyStroke
    ) -> SwimTerminalNavigatorResult {
        switch interpreter.handle(
            SwimTerminalInputAdapter.input(
                for: keyStroke
            )
        ) {
        case .pending:
            return .pending

        case .cancelled:
            return .cancelled

        case .unhandled:
            return .unhandled(
                keyStroke.key
            )

        case .navigate(let step, let count):
            return .command(
                Self.command(
                    for: step,
                    count: count
                )
            )
        }
    }

    static func command(
        for step: NavigationStep,
        count: Int
    ) -> TerminalNavigationCommand {
        switch step {
        case .up:
            return .vertical(-count)

        case .down:
            return .vertical(count)

        case .left:
            return .horizontal(-count)

        case .right:
            return .horizontal(count)

        case .first:
            return .first

        case .last:
            return .last

        case .position(let position):
            return .position(
                max(0, position - 1)
            )

        case .pageUp:
            return .page(-count)

        case .pageDown:
            return .page(count)

        case .halfPageUp:
            return .halfPage(-count)

        case .halfPageDown:
            return .halfPage(count)
        }
    }
}
