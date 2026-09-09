import SwimInterpreter
import Terminal

public enum SwimTerminalInput:
    Sendable,
    Codable,
    Hashable
{
    case input(SwimInterpreter.Input)
    case paste(String)
}

public enum SwimTerminalInputAdapter {
    public static func adapt(
        _ event: TerminalInputEvent
    ) -> SwimTerminalInput {
        switch event {
        case .key(let key):
            return .input(
                input(
                    for: key
                )
            )

        case .keyStroke(let keyStroke):
            return .input(
                input(
                    for: keyStroke
                )
            )

        case .paste(let text):
            return .paste(
                text
            )
        }
    }

    public static func input(
        for keyStroke: TerminalKeyStroke
    ) -> SwimInterpreter.Input {
        if keyStroke.modifiers.contains(
            .control
        ) {
            switch keyStroke.key {
            case .space:
                return .controlSpace

            case .char(let key):
                return .control(
                    key.uppercased()
                )

            default:
                break
            }
        }

        return input(
            for: keyStroke.key
        )
    }

    public static func input(
        for key: TerminalKey
    ) -> SwimInterpreter.Input {
        switch key {
        case .up:
            return .up

        case .down:
            return .down

        case .left:
            return .left

        case .right:
            return .right

        case .home:
            return .home

        case .end:
            return .end

        case .pageUp:
            return .pageUp

        case .pageDown:
            return .pageDown

        case .insert:
            return .insert

        case .delete:
            return .delete

        case .enter:
            return .enter

        case .escape:
            return .escape

        case .backspace:
            return .backspace

        case .tab:
            return .tab

        case .space:
            return .space

        case .controlSpace:
            return .controlSpace

        case .control(let key):
            return .control(
                key
            )

        case .char(let key):
            return .char(
                key
            )

        case .unknown:
            return .unknown
        }
    }
}
