import Swim
import SwimTerminal
import Terminal

enum SwimTerminalFollowEndSmoke {
    enum Failure:
        Error
    {
        case initialFollow
        case streamingFollow
        case detachedFollow
        case resumedFollow
        case scrollOptimization
        case replacementOptimization
    }

    static func run() throws {
        var surface = SwimTerminalSurface(
            editor: SwimEditor(
                text: "1\n2\n3\n4",
                bufferModifiability: .nonmodifiable
            ),
            visibleRows: 3,
            followEnd: true,
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

        guard surface.isFollowingEnd,
              surface.viewport.isAtEnd else {
            throw Failure.initialFollow
        }

        frame.removeAll()

        guard surface.append(
            "\n5"
        ) else {
            throw Failure.streamingFollow
        }

        surface.render(
            into: &frame,
            in: region,
            atNanoseconds: 1
        )

        guard surface.isFollowingEnd,
              surface.viewport.isAtEnd else {
            throw Failure.streamingFollow
        }

        guard frame.scrolls.contains(
            where: {
                $0.delta == 1
            }
        ) else {
            throw Failure.scrollOptimization
        }

        guard surface.handle(
            .up,
            nowNanoseconds: 2
        ) == .changed,
        !surface.isFollowingEnd else {
            throw Failure.detachedFollow
        }

        let detachedCursor = surface.editor.buffer.cursor

        guard surface.append(
            "\n6"
        ),
        surface.editor.buffer.cursor == detachedCursor,
        !surface.isFollowingEnd else {
            throw Failure.detachedFollow
        }

        frame.removeAll()
        surface.render(
            into: &frame,
            in: region,
            atNanoseconds: 3
        )

        guard !surface.viewport.isAtEnd else {
            throw Failure.detachedFollow
        }

        guard surface.handle(
            .char(
                "G"
            ),
            nowNanoseconds: 4
        ) == .changed,
        surface.isFollowingEnd,
        surface.editor.buffer.cursor.offset
            == surface.editor.buffer.characterCount else {
            throw Failure.resumedFollow
        }

        frame.removeAll()
        surface.render(
            into: &frame,
            in: region,
            atNanoseconds: 5
        )
        frame.removeAll()

        surface.replace(
            with: "alpha\nbeta\ngamma\ndelta\nepsilon\nzeta"
        )
        surface.render(
            into: &frame,
            in: region,
            atNanoseconds: 6
        )

        guard frame.scrolls.isEmpty else {
            throw Failure.replacementOptimization
        }
    }
}
