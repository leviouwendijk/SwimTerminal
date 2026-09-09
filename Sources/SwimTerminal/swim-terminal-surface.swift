import Dispatch
import Swim
import SwimInterpreter
import Terminal

public enum SwimTerminalSurfacePresentation:
    Sendable,
    Hashable
{
    case compact
    case expanded
}

public struct SwimTerminalSurfaceSizePolicy:
    Sendable,
    Hashable
{
    public var minimumRows: Int
    public var maximumRows: Int

    public init(
        minimumRows: Int = 1,
        maximumRows: Int = 6
    ) {
        let minimumRows = max(
            1,
            minimumRows
        )

        self.minimumRows = minimumRows
        self.maximumRows = max(
            minimumRows,
            maximumRows
        )
    }

    public func rows(
        forContentRows contentRows: Int
    ) -> Int {
        min(
            maximumRows,
            max(
                minimumRows,
                contentRows
            )
        )
    }
}

public struct SwimTerminalSurface:
    Sendable
{
    public private(set) var editor: SwimEditor
    public internal(set) var viewport: TerminalViewport
    public var configuration: SwimTerminalConfiguration
    public var sizePolicy: SwimTerminalSurfaceSizePolicy
    public private(set) var surfacePresentation:
        SwimTerminalSurfacePresentation
    public var compactPresentation: SwimTerminalPresentation
    public var expandedPresentation: SwimTerminalPresentation
    public var placeholder: String
    public var placeholderStyle: TerminalStyle
    public private(set) var yankPresentation:
        SwimTerminalYankPresentation?

    var renderState: RenderState?

    public init(
        editor: SwimEditor = .init(),
        visibleRows: Int = 0,
        configuration: SwimTerminalConfiguration = .init(),
        sizePolicy: SwimTerminalSurfaceSizePolicy = .init(),
        surfacePresentation: SwimTerminalSurfacePresentation = .compact,
        compactPresentation: SwimTerminalPresentation = .compact,
        expandedPresentation: SwimTerminalPresentation = .expanded,
        placeholder: String = "",
        placeholderStyle: TerminalStyle = .dim
    ) {
        self.editor = editor
        viewport = TerminalViewport(
            visibleRows: visibleRows
        )
        self.configuration = configuration
        self.sizePolicy = sizePolicy
        self.surfacePresentation = surfacePresentation
        self.compactPresentation = compactPresentation
        self.expandedPresentation = expandedPresentation
        self.placeholder = placeholder
        self.placeholderStyle = placeholderStyle
        yankPresentation = nil
        renderState = nil
    }

    public var text: String {
        editor.buffer.text
    }

    public var mode: SwimInterpreter.Mode {
        editor.mode
    }

    public var presentation: SwimTerminalPresentation {
        presentation(
            for: surfacePresentation
        )
    }

    public var nextPresentationDeadlineNanoseconds: UInt64? {
        yankPresentation?.expiresAtNanoseconds
    }

    public func activeYankRanges(
        atNanoseconds now: UInt64 =
            DispatchTime.now().uptimeNanoseconds
    ) -> [Range<Int>] {
        guard let yankPresentation,
              yankPresentation.isActive(
                atNanoseconds: now
              ) else {
            return []
        }

        return yankPresentation.sourceRanges
    }

    public func activeYankRange(
        atNanoseconds now: UInt64 =
            DispatchTime.now().uptimeNanoseconds
    ) -> Range<Int>? {
        activeYankRanges(
            atNanoseconds: now
        ).first
    }

    @discardableResult
    public mutating func handle(
        _ event: TerminalInputEvent,
        nowNanoseconds: UInt64 =
            DispatchTime.now().uptimeNanoseconds
    ) -> SwimEditorEvent? {
        let bridge = SwimTerminalBridge(
            configuration: configuration
        )
        let result = bridge.handle(
            event,
            editor: &editor,
            pageRows: max(
                1,
                viewport.visibleRows
            )
        )

        if case .copyRequested(let copy)? = result {
            yankPresentation = SwimTerminalYankPresentation(
                copy: copy,
                startedAtNanoseconds: nowNanoseconds
            )
        }

        return result
    }

    @discardableResult
    public mutating func handle(
        _ key: TerminalKey,
        nowNanoseconds: UInt64 =
            DispatchTime.now().uptimeNanoseconds
    ) -> SwimEditorEvent? {
        handle(
            .key(
                key
            ),
            nowNanoseconds: nowNanoseconds
        )
    }

    public mutating func replace(
        with text: String
    ) {
        editor.replace(
            with: text
        )
        yankPresentation = nil
        renderState = nil
    }

    public mutating func clear() {
        replace(
            with: ""
        )
    }

    public mutating func setMode(
        _ mode: SwimInterpreter.Mode
    ) {
        editor.setMode(
            mode
        )
    }

    public mutating func setSurfacePresentation(
        _ presentation: SwimTerminalSurfacePresentation
    ) {
        surfacePresentation = presentation
        renderState = nil
    }

    public mutating func toggleSurfacePresentation() {
        setSurfacePresentation(
            surfacePresentation == .compact
                ? .expanded
                : .compact
        )
    }

    public func contentRowCount(
        columns: Int
    ) -> Int {
        contentRowCount(
            columns: columns,
            surfacePresentation: surfacePresentation
        )
    }

    public func compactRows(
        columns: Int
    ) -> Int {
        sizePolicy.rows(
            forContentRows: contentRowCount(
                columns: columns,
                surfacePresentation: .compact
            )
        )
    }

    public func resolvedRows(
        columns: Int,
        availableRows: Int
    ) -> Int {
        let availableRows = max(
            0,
            availableRows
        )

        guard availableRows > 0 else {
            return 0
        }

        switch surfacePresentation {
        case .compact:
            return min(
                availableRows,
                compactRows(
                    columns: columns
                )
            )

        case .expanded:
            return availableRows
        }
    }

    func editorContext(
        pageRows: Int
    ) -> SwimEditorContext {
        SwimEditorContext(
            pageRows: max(
                1,
                pageRows
            ),
            displayColumns:
                SwimTerminalDisplayColumnMappingProvider(
                    tabWidth: configuration.tabWidth
                )
        )
    }

    func activeYankPresentation(
        atNanoseconds now: UInt64
    ) -> SwimTerminalYankPresentation? {
        guard let yankPresentation,
              yankPresentation.isActive(
                atNanoseconds: now
              ) else {
            return nil
        }

        return yankPresentation
    }

    func presentation(
        for surfacePresentation: SwimTerminalSurfacePresentation
    ) -> SwimTerminalPresentation {
        switch surfacePresentation {
        case .compact:
            return compactPresentation

        case .expanded:
            return expandedPresentation
        }
    }

    private func contentRowCount(
        columns: Int,
        surfacePresentation: SwimTerminalSurfacePresentation
    ) -> Int {
        let columns = max(
            1,
            columns
        )
        let presentation = presentation(
            for: surfacePresentation
        )
        let gutterColumns = presentation.lineNumbers.gutterColumns(
            availableColumns: columns
        )
        let textColumns = max(
            1,
            columns - gutterColumns
        )

        return TerminalTextLayout(
            text: editor.buffer.text,
            columns: textColumns,
            tabWidth: configuration.tabWidth
        ).rows.count
    }

    struct RenderState:
        Sendable
    {
        var text: String
        var region: TerminalRegion
        var contentColumns: Int
        var offset: Int
    }
}
