import Clipboard
import Swim
import Terminal

public struct SwimTerminalBridge:
    Sendable
{
    public var configuration: SwimTerminalConfiguration

    public init(
        configuration: SwimTerminalConfiguration = .init()
    ) {
        self.configuration = configuration
    }

    @discardableResult
    public func handle(
        _ event: TerminalInputEvent,
        editor: inout SwimEditor,
        pageRows: Int = 1
    ) -> SwimEditorEvent? {
        let context = SwimEditorContext(
            pageRows: pageRows,
            displayColumns:
                SwimTerminalDisplayColumnMappingProvider(
                    tabWidth: configuration.tabWidth
                )
        )
        let result: SwimEditorEvent?

        switch SwimTerminalInputAdapter.adapt(
            event
        ) {
        case .input(let input):
            result = editor.handle(
                input,
                context: context
            )

        case .paste(let text):
            result = editor.paste(
                text,
                context: context
            )
        }

        if case .copyRequested(let copy)? = result,
           configuration.yankClipboardPolicy == .systemClipboard
        {
            _ = Clipboard.system.write(
                copy.text
            )
        }

        return result
    }
}
