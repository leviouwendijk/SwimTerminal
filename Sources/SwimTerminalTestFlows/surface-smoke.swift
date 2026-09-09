import Swim
import SwimTerminal
import Terminal

enum SwimTerminalSurfaceSmoke {
    enum Failure:
        Error
    {
        case unexpectedPresentation
        case unexpectedViewport
        case unexpectedCursorShape
        case unexpectedSelection
        case unexpectedYank
        case unexpectedYankExpiration
        case unexpectedIndentationGuides
        case unexpectedCommandLine
        case unexpectedSizing
    }

    static func run() throws {
        try runPresentationProbe()
        try runViewportAndCursorProbe()
        try runSelectionAndYankProbe()
        try runIndentationGuideProbe()
        try runCommandLineProbe()
        try runSizingProbe()
    }

    private static func runPresentationProbe() throws {
        guard SwimTerminalPresentation.compact
            .lineNumbers.mode == .hidden,
        SwimTerminalPresentation.expanded
            .lineNumbers.mode == .hybrid else {
            throw Failure.unexpectedPresentation
        }
    }

    private static func runViewportAndCursorProbe() throws {
        var surface = SwimTerminalSurface(
            editor: SwimEditor(
                text: (1...8)
                    .map {
                        "line \($0)"
                    }
                    .joined(
                        separator: "\n"
                    )
            ),
            configuration: SwimTerminalConfiguration(
                yankClipboardPolicy: .registerOnly
            ),
            surfacePresentation: .expanded
        )
        let region = TerminalRegion(
            rows: 3,
            columns: 20
        )
        var frame = TerminalFrame(
            rows: 3,
            columns: 20
        )

        surface.render(
            into: &frame,
            in: region,
            atNanoseconds: 0
        )

        guard surface.viewport.isAtEnd,
              frame.cursor?.shape == .block,
              frame.spans.contains(
                where: {
                    $0.content.contains(
                        "8 "
                    )
                }
              ) else {
            throw Failure.unexpectedViewport
        }

        surface.setMode(
            .insert
        )
        frame.removeAll()
        surface.render(
            into: &frame,
            in: region,
            atNanoseconds: 0
        )

        guard frame.cursor?.shape == .bar else {
            throw Failure.unexpectedCursorShape
        }

        surface.setMode(
            .replace
        )
        frame.removeAll()
        surface.render(
            into: &frame,
            in: region,
            atNanoseconds: 0
        )

        guard frame.cursor?.shape == .underline else {
            throw Failure.unexpectedCursorShape
        }

        surface.setMode(
            .normal
        )
    }

    private static func runSelectionAndYankProbe() throws {
        var surface = SwimTerminalSurface(
            editor: SwimEditor(
                text: "abc"
            ),
            configuration: SwimTerminalConfiguration(
                yankClipboardPolicy: .registerOnly
            )
        )

        guard surface.handle(
            .home,
            nowNanoseconds: 1
        ) == .changed,
        surface.handle(
            .char(
                "v"
            ),
            nowNanoseconds: 2
        ) == .changed,
        surface.handle(
            .right,
            nowNanoseconds: 3
        ) == .changed else {
            throw Failure.unexpectedSelection
        }

        var frame = TerminalFrame(
            rows: 1,
            columns: 12
        )

        surface.render(
            into: &frame,
            in: TerminalRegion(
                rows: 1,
                columns: 12
            ),
            atNanoseconds: 4
        )

        guard frame.spans.contains(
            where: {
                $0.content.contains(
                    "\u{001B}[48;2;58;61;67m"
                )
            }
        ) else {
            throw Failure.unexpectedSelection
        }

        let yankStart: UInt64 = 100

        guard case .copyRequested(let copy)? = surface.handle(
            .char(
                "y"
            ),
            nowNanoseconds: yankStart
        ),
        copy.text == "ab",
        surface.activeYankRanges(
            atNanoseconds: yankStart + 1
        ) == [
            0..<2,
        ],
        surface.nextPresentationDeadlineNanoseconds
            == yankStart
                + SwimTerminalYankPresentation
                    .standardDurationNanoseconds else {
            throw Failure.unexpectedYank
        }

        frame.removeAll()
        surface.render(
            into: &frame,
            in: TerminalRegion(
                rows: 1,
                columns: 12
            ),
            atNanoseconds: yankStart + 1
        )

        guard frame.spans.contains(
            where: {
                $0.content.contains(
                    "\u{001B}[103m"
                )
            }
        ) else {
            throw Failure.unexpectedYank
        }

        guard surface.activeYankRanges(
            atNanoseconds:
                yankStart
                + SwimTerminalYankPresentation
                    .standardDurationNanoseconds
        ).isEmpty else {
            throw Failure.unexpectedYankExpiration
        }
    }

    private static func runIndentationGuideProbe() throws {
        var surface = SwimTerminalSurface(
            editor: SwimEditor(
                text: "        value"
            ),
            configuration: SwimTerminalConfiguration(
                yankClipboardPolicy: .registerOnly
            ),
            compactPresentation: SwimTerminalPresentation(
                indentationGuides: TerminalIndentationGuideOptions(
                    isEnabled: true,
                    width: 4
                )
            )
        )
        var frame = TerminalFrame(
            rows: 1,
            columns: 20
        )

        surface.render(
            into: &frame,
            in: TerminalRegion(
                rows: 1,
                columns: 20
            ),
            atNanoseconds: 0
        )

        guard frame.spans.contains(
            where: {
                $0.content.contains(
                    "│"
                )
            }
        ) else {
            throw Failure.unexpectedIndentationGuides
        }
    }

    private static func runCommandLineProbe() throws {
        var surface = SwimTerminalSurface(
            editor: SwimEditor(
                text: "abc"
            ),
            configuration: SwimTerminalConfiguration(
                yankClipboardPolicy: .registerOnly
            )
        )

        guard surface.handle(
            .char(
                ":"
            ),
            nowNanoseconds: 1
        ) == .changed,
        surface.commandLine.isActive,
        surface.handle(
            .char(
                "q"
            ),
            nowNanoseconds: 2
        ) == .changed else {
            throw Failure.unexpectedCommandLine
        }

        var frame = TerminalFrame(
            rows: 2,
            columns: 20
        )

        surface.render(
            into: &frame,
            in: TerminalRegion(
                rows: 2,
                columns: 20
            ),
            atNanoseconds: 3
        )

        guard surface.compactRows(
            columns: 20
        ) == 2,
        frame.cursor?.shape == .bar,
        frame.spans.contains(
                where: {
                    $0.content.contains(
                        ":q"
                    )
                }
              ),
              surface.handle(
                .enter,
                nowNanoseconds: 4
              ) == .commandRequested(
                .quit
              ),
              !surface.commandLine.isActive else {
            throw Failure.unexpectedCommandLine
        }

        guard surface.handle(
            .char(
                ":"
            ),
            nowNanoseconds: 5
        ) == .changed,
        surface.handle(
            .char(
                "w"
            ),
            nowNanoseconds: 6
        ) == .changed,
        surface.handle(
            .enter,
            nowNanoseconds: 7
        ) == .commandRequested(
            .write
        ) else {
            throw Failure.unexpectedCommandLine
        }

        surface.setCommandStatus(
            "written"
        )
        frame.removeAll()
        surface.render(
            into: &frame,
            in: TerminalRegion(
                rows: 2,
                columns: 20
            ),
            atNanoseconds: 8
        )

        guard frame.spans.contains(
            where: {
                $0.content.contains(
                    "written"
                )
            }
        ) else {
            throw Failure.unexpectedCommandLine
        }

        guard surface.handle(
            .char(
                ":"
            ),
            nowNanoseconds: 9
        ) == .changed,
        surface.handle(
            .char(
                "nope"
            ),
            nowNanoseconds: 10
        ) == .changed,
        surface.handle(
            .enter,
            nowNanoseconds: 11
        ) == .invalidCommand(
            "nope"
        ),
        surface.commandLine.status
            == "Not an editor command: nope" else {
            throw Failure.unexpectedCommandLine
        }

        guard surface.handle(
            .char(
                ":"
            ),
            nowNanoseconds: 12
        ) == .changed,
        surface.commandLine.isActive,
        surface.handle(
            .escape,
            nowNanoseconds: 13
        ) == .changed,
        !surface.commandLine.isActive else {
            throw Failure.unexpectedCommandLine
        }
    }

    private static func runSizingProbe() throws {
        var surface = SwimTerminalSurface(
            editor: SwimEditor(
                text: "a\nb\nc\nd"
            ),
            sizePolicy: SwimTerminalSurfaceSizePolicy(
                minimumRows: 1,
                maximumRows: 2
            )
        )

        guard surface.contentRowCount(
            columns: 20
        ) == 4,
        surface.compactRows(
            columns: 20
        ) == 2,
        surface.resolvedRows(
            columns: 20,
            availableRows: 10
        ) == 2 else {
            throw Failure.unexpectedSizing
        }

        surface.toggleSurfacePresentation()

        guard surface.surfacePresentation == .expanded,
              surface.resolvedRows(
                columns: 20,
                availableRows: 10
              ) == 10 else {
            throw Failure.unexpectedSizing
        }
    }
}
