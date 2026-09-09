import Terminal

public struct SwimTerminalPresentation:
    Sendable,
    Hashable
{
    public var lineNumbers: TerminalLineNumberPresentation
    public var selectionStyle: TerminalStyle
    public var yankStyle: TerminalStyle
    public var indentationGuides: TerminalIndentationGuideOptions
    public var cursorRevealMargin: Int

    public init(
        lineNumbers: TerminalLineNumberPresentation = .init(),
        selectionStyle: TerminalStyle = TerminalStyle(
            foreground: .rgb(
                red: 208,
                green: 208,
                blue: 208
            ),
            background: .rgb(
                red: 58,
                green: 61,
                blue: 67
            )
        ),
        yankStyle: TerminalStyle = TerminalStyle(
            .black,
            .brightYellowBackground
        ),
        indentationGuides: TerminalIndentationGuideOptions = .init(),
        cursorRevealMargin: Int = 1
    ) {
        self.lineNumbers = lineNumbers
        self.selectionStyle = selectionStyle
        self.yankStyle = yankStyle
        self.indentationGuides = indentationGuides
        self.cursorRevealMargin = max(
            0,
            cursorRevealMargin
        )
    }

    public static let compact =
        SwimTerminalPresentation()

    public static let expanded =
        SwimTerminalPresentation(
            lineNumbers: TerminalLineNumberPresentation(
                mode: .hybrid
            )
        )
}
