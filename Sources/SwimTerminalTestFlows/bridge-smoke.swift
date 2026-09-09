import Swim
import SwimInterpreter
import SwimTerminal
import Terminal

enum SwimTerminalBridgeSmoke {
    enum Failure:
        Error
    {
        case unexpectedConfiguration
        case unexpectedInput
        case unexpectedPaste
        case unexpectedYank
        case unexpectedDisplayColumns
    }

    static func run() throws {
        try runConfigurationProbe()
        try runInputProbe()
        try runPasteProbe()
        try runYankProbe()
        try runDisplayColumnProbe()
    }

    private static func runConfigurationProbe() throws {
        let configuration = SwimTerminalConfiguration()

        guard configuration.yankClipboardPolicy == .systemClipboard,
              configuration.tabWidth == 4 else {
            throw Failure.unexpectedConfiguration
        }
    }

    private static func runInputProbe() throws {
        guard SwimTerminalInputAdapter.input(
            for: .up
        ) == .up,
        SwimTerminalInputAdapter.input(
            for: .control(
                "R"
            )
        ) == .control(
            "R"
        ),
        SwimTerminalInputAdapter.input(
            for: TerminalKeyStroke(
                key: .char(
                    "r"
                ),
                modifiers: .control
            )
        ) == .control(
            "R"
        ),
        SwimTerminalInputAdapter.adapt(
            .paste(
                "hello"
            )
        ) == .paste(
            "hello"
        ) else {
            throw Failure.unexpectedInput
        }
    }

    private static func runPasteProbe() throws {
        let bridge = SwimTerminalBridge(
            configuration: SwimTerminalConfiguration(
                yankClipboardPolicy: .registerOnly
            )
        )
        var editor = SwimEditor()

        guard bridge.handle(
            .key(
                .char(
                    "i"
                )
            ),
            editor: &editor
        ) == .changed,
        bridge.handle(
            .paste(
                "hello"
            ),
            editor: &editor
        ) == .changed,
        editor.buffer.text == "hello" else {
            throw Failure.unexpectedPaste
        }
    }

    private static func runYankProbe() throws {
        let bridge = SwimTerminalBridge(
            configuration: SwimTerminalConfiguration(
                yankClipboardPolicy: .registerOnly
            )
        )
        var editor = SwimEditor(
            text: "abc"
        )

        guard bridge.handle(
            .key(
                .home
            ),
            editor: &editor
        ) == .changed,
        bridge.handle(
            .key(
                .char(
                    "v"
                )
            ),
            editor: &editor
        ) == .changed,
        case .copyRequested(let copy)? = bridge.handle(
            .key(
                .char(
                    "y"
                )
            ),
            editor: &editor
        ),
        copy.text == "a",
        editor.registers.unnamed == .character(
            "a"
        ) else {
            throw Failure.unexpectedYank
        }
    }

    private static func runDisplayColumnProbe() throws {
        let provider = SwimTerminalDisplayColumnMappingProvider(
            tabWidth: 4
        )
        let mapping = provider.mapping(
            for: "a\t界"
        )

        let terminalWideCharacterWidth = TerminalDisplay.width(
            of: "界"
        )

        guard terminalWideCharacterWidth > 0,
              mapping.width(
                ofLine: 1
              ) == 4 + terminalWideCharacterWidth else {
            throw Failure.unexpectedDisplayColumns
        }
    }
}
