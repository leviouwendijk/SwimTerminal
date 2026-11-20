import Swim
import SwimTerminal
import Terminal

enum SwimTerminalRejectionSmoke {
    enum Failure:
        Error
    {
        case editingRejection
        case pasteRejection
        case presentation
    }

    static func run() throws {
        var surface = SwimTerminalSurface(
            editor: SwimEditor(
                text: "alpha beta",
                bufferModifiability: .nonmodifiable
            ),
            configuration: SwimTerminalConfiguration(
                yankClipboardPolicy: .registerOnly
            )
        )
        let rejection = SwimEditorRejection(
            reason: .bufferNonmodifiable
        )

        guard surface.handle(
            .char(
                "i"
            ),
            nowNanoseconds: 0
        ) == .rejected(
            rejection
        ),
        surface.editor.buffer.text == "alpha beta",
        surface.editor.mode == .normal,
        surface.commandLine.status
            == "E21: Cannot make changes, 'modifiable' is off" else {
            throw Failure.editingRejection
        }

        guard surface.handle(
            .paste(
                "blocked"
            ),
            nowNanoseconds: 1
        ) == .rejected(
            rejection
        ),
        surface.editor.buffer.text == "alpha beta" else {
            throw Failure.pasteRejection
        }

        var frame = TerminalFrame(
            rows: 3,
            columns: 64
        )
        surface.render(
            into: &frame,
            in: TerminalRegion(
                rows: 3,
                columns: 64
            ),
            atNanoseconds: 2
        )

        guard !frame.spans.isEmpty else {
            throw Failure.presentation
        }
    }
}
