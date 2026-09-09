import Dispatch
import Swim
import SwimTerminal
import Terminal

enum SwimTerminalSurfaceLab {
    private enum Action: Sendable {
        case unused
    }

    static func run() throws {
        let stream = TerminalStream.standardError
        let session = try TerminalSession(
            options: TerminalSession.Options(
                useAlternateScreen: true,
                hideCursor: true,
                useRawMode: true,
                useBracketedPaste: true,
                controlSignalBehavior: .input,
                restoreOnInterrupt: true,
                outputStream: stream
            )
        )

        defer {
            session.restore()
        }

        let reader = TerminalKeyReader()
        var renderer = TerminalFrameRenderer(
            stream: stream
        )
        var keyMap = TerminalKeyMap<Action>()
        keyMap.remap(
            .control("C"),
            to: .escape
        )
        var size = Terminal.size(
            for: stream
        )
        var surface = SwimTerminalSurface(
            editor: SwimEditor(
                text: fixture
            ),
            compactPresentation: SwimTerminalPresentation(
                lineNumbers: TerminalLineNumberPresentation(
                    mode: .hybrid
                ),
                indentationGuides: TerminalIndentationGuideOptions(
                    isEnabled: true,
                    width: 4
                )
            ),
            expandedPresentation: SwimTerminalPresentation(
                lineNumbers: TerminalLineNumberPresentation(
                    mode: .hybrid
                ),
                indentationGuides: TerminalIndentationGuideOptions(
                    isEnabled: true,
                    width: 4
                )
            )
        )
        var lastExpiredPresentationDeadline: UInt64?

        func render() {
            var frame = TerminalFrame(
                rows: size.rows,
                columns: size.columns
            )

            guard size.rows > 0,
                  size.columns > 0 else {
                renderer.render(
                    frame
                )
                return
            }

            let header = TerminalDisplay.clipped(
                "SwimTerminal · Ctrl-F compact/expanded · :w write request · :q quit",
                columns: size.columns
            )

            frame.write(
                TerminalStyle.dim.apply(
                    header
                ),
                in: TerminalRegion(
                    rows: 1,
                    columns: size.columns
                )
            )

            let availableRows = max(
                0,
                size.rows - 1
            )
            let surfaceRows = surface.resolvedRows(
                columns: size.columns,
                availableRows: availableRows
            )

            if surfaceRows > 0 {
                surface.render(
                    into: &frame,
                    in: TerminalRegion(
                        top: 1,
                        rows: surfaceRows,
                        columns: size.columns
                    )
                )
            }

            renderer.render(
                frame
            )
        }

        render()

        while true {
            let events = reader.readEvents(
                timeoutMilliseconds: 50,
                maximumCount: 128
            )
            var needsRender = false
            let currentSize = Terminal.size(
                for: stream
            )

            if currentSize != size {
                size = currentSize
                needsRender = true
            }

            let now = DispatchTime.now()
                .uptimeNanoseconds

            if let deadline =
                surface.nextPresentationDeadlineNanoseconds,
               deadline <= now,
               lastExpiredPresentationDeadline != deadline
            {
                lastExpiredPresentationDeadline = deadline
                needsRender = true
            }

            for input in events {
                if !surface.commandLine.isActive {
                    switch input.legacyKey {
                    case .control(let key)
                    where key.uppercased() == "F":
                        surface.toggleSurfacePresentation()
                        needsRender = true
                        continue

                    default:
                        break
                    }
                }

                let routedInput: TerminalInputEvent

                switch input.legacyKey {
                case .control(let key)
                where key.uppercased() == "C":
                    switch keyMap.resolveOrFallback(
                        input.legacyKey
                    ) {
                    case .key(let key):
                        routedInput = .key(
                            key
                        )

                    case .action(_),
                         .consumed:
                        continue
                    }

                default:
                    routedInput = input
                }

                guard let event = surface.handle(
                    routedInput
                ) else {
                    continue
                }

                switch event {
                case .changed:
                    needsRender = true

                case .copyRequested:
                    lastExpiredPresentationDeadline = nil
                    needsRender = true

                case .commandRequested(.write):
                    surface.setCommandStatus(
                        "write requested — this lab does not persist"
                    )
                    needsRender = true

                case .commandRequested(.quit):
                    switch surface.surfacePresentation {
                    case .expanded:
                        surface.setSurfacePresentation(
                            .compact
                        )
                        needsRender = true

                    case .compact:
                        return
                    }

                case .invalidCommand:
                    needsRender = true

                case .cancelRequested:
                    needsRender = true
                }
            }

            if needsRender {
                render()
            }
        }
    }

    private static let fixture = """
    SwimTerminal surface laboratory

    This buffer is owned by one headless SwimEditor.
    Terminal owns the frame, viewport, layout and input transport.
    SwimTerminal binds the two layers together.

        indentation guides begin here
        use motions, Visual mode, yank, paste and undo

    Wide character fixture: 界
    Tab fixture:\talpha\tbeta

    Ctrl-C behaves as Escape and never terminates the laboratory.
    Ctrl-F toggles compact and expanded presentation.
    Compact and expanded presentations both show hybrid line numbers.
    :w emits a typed write request but does not touch the filesystem.
    :q collapses expanded presentation; from compact presentation it exits.
    """
}
