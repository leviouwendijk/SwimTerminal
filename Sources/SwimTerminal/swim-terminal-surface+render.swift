import Dispatch
import Swim
import SwimInterpreter
import Terminal

extension SwimTerminalSurface {
    mutating func renderEditor(
        into frame: inout TerminalFrame,
        in region: TerminalRegion,
        isFocused: Bool = true,
        atNanoseconds now: UInt64 =
            DispatchTime.now().uptimeNanoseconds
    ) {
        guard !region.isEmpty else {
            return
        }

        let presentation = self.presentation
        let gutterColumns = presentation.lineNumbers.gutterColumns(
            availableColumns: region.columns
        )
        let textColumns = max(
            1,
            region.columns - gutterColumns
        )
        let layout = TerminalTextLayout(
            text: editor.buffer.text,
            columns: textColumns,
            tabWidth: configuration.tabWidth
        )
        let cursor = layout.position(
            forCursorOffset: editor.buffer.cursor.offset
        )
        let currentLineNumber = layout.rows[
            cursor.row
        ].sourceLineNumber

        viewport.update(
            contentRows: layout.rows.count,
            visibleRows: region.rows
        )
        viewport.reveal(
            row: cursor.row,
            margin: min(
                presentation.cursorRevealMargin,
                max(
                    0,
                    region.rows - 1
                )
            )
        )

        if let renderState,
           renderState.text == editor.buffer.text,
           renderState.region == region,
           renderState.contentColumns == textColumns
        {
            frame.scrollRows(
                in: region,
                by:
                    viewport.offset
                    - renderState.offset
            )
        }

        renderState = RenderState(
            text: editor.buffer.text,
            region: region,
            contentColumns: textColumns,
            offset: viewport.offset
        )

        let context = editorContext(
            pageRows: region.rows
        )
        let selectionRanges =
            editor.mode == .visual
            ? editor.selectionRanges(
                context: context
            ).map { range in
                range.offsets
            }
            : []
        let lineSelectionRange: Range<Int>?

        if editor.mode == .visual,
           editor.selection?.kind == .line {
            lineSelectionRange = selectionRanges.first
        } else {
            lineSelectionRange = nil
        }

        let yankPresentation = activeYankPresentation(
            atNanoseconds: now
        )
        let yankRanges = yankPresentation?.sourceRanges
            ?? []
        var decorations: [TerminalTextDecoration] = []

        if lineSelectionRange == nil,
           !selectionRanges.isEmpty {
            decorations.append(
                TerminalTextDecoration(
                    sourceRanges: selectionRanges,
                    style: presentation.selectionStyle
                )
            )
        }

        if !yankRanges.isEmpty {
            decorations.append(
                TerminalTextDecoration(
                    sourceRanges: yankRanges,
                    style: presentation.yankStyle
                )
            )
        }

        for visualRow in viewport.visibleRange {
            let layoutRow = layout.rows[
                visualRow
            ]
            let outputRow =
                region.top
                + visualRow
                - viewport.offset
            let rendered = renderedLineSelectionContent(
                layoutRow,
                columns: textColumns,
                options: presentation.indentationGuides,
                selectionRange: lineSelectionRange,
                selectionStyle: presentation.selectionStyle
            )
                ?? renderedIndentationGuides(
                    in: layoutRow.renderedContent(
                        decorations: decorations
                    ),
                    row: layoutRow,
                    options: presentation.indentationGuides,
                    selectionRanges: selectionRanges,
                    selectionStyle: presentation.selectionStyle,
                    yankRanges: yankRanges,
                    yankStyle: presentation.yankStyle
                )

            if gutterColumns > 0 {
                let lineNumber = presentation.lineNumbers.text(
                    sourceLineNumber: layoutRow.sourceLineNumber,
                    currentLineNumber: currentLineNumber,
                    isSourceLineStart: layoutRow.isSourceLineStart,
                    gutterColumns: gutterColumns
                )
                let lineNumberStyle = presentation.lineNumbers.style(
                    sourceLineNumber: layoutRow.sourceLineNumber,
                    currentLineNumber: currentLineNumber
                )

                frame.write(
                    lineNumberStyle.apply(
                        TerminalDisplay.fitted(
                            lineNumber,
                            columns: gutterColumns
                        )
                    ),
                    in: TerminalRegion(
                        top: outputRow,
                        leading: region.leading,
                        rows: 1,
                        columns: gutterColumns
                    )
                )
            }

            frame.write(
                rendered,
                in: TerminalRegion(
                    top: outputRow,
                    leading: region.leading + gutterColumns,
                    rows: 1,
                    columns: textColumns
                )
            )
        }

        if editor.buffer.text.isEmpty,
           !placeholder.isEmpty,
           viewport.visibleRange.contains(
            cursor.row
           )
        {
            frame.write(
                placeholderStyle.apply(
                    TerminalDisplay.clipped(
                        placeholder,
                        columns: textColumns
                    )
                ),
                in: TerminalRegion(
                    top:
                        region.top
                        + cursor.row
                        - viewport.offset,
                    leading: region.leading + gutterColumns,
                    rows: 1,
                    columns: textColumns
                )
            )
        }

        guard isFocused,
              viewport.visibleRange.contains(
                cursor.row
              ) else {
            return
        }

        frame.placeCursor(
            row:
                region.top
                + cursor.row
                - viewport.offset,
            column:
                region.leading
                + gutterColumns
                + min(
                    cursor.column,
                    max(
                        0,
                        textColumns - 1
                    )
                ),
            shape: cursorShape
        )
    }

    var cursorShape: TerminalCursorShape {
        switch editor.mode {
        case .insert:
            return .bar

        case .replace:
            return .underline

        case .normal,
             .visual:
            return .block
        }
    }

    private func renderedLineSelectionContent(
        _ row: TerminalTextLayoutRow,
        columns: Int,
        options: TerminalIndentationGuideOptions,
        selectionRange: Range<Int>?,
        selectionStyle: TerminalStyle
    ) -> String? {
        guard let selectionRange,
              range(
                selectionRange,
                touches: row
              ) else {
            return nil
        }

        var content = row.content

        if options.isEnabled,
           row.isSourceLineStart {
            let leadingColumns = row.content.prefix {
                $0 == " "
            }.count
            let glyph = TerminalDisplay.fitted(
                options.glyph,
                columns: 1
            )

            if leadingColumns > 0,
               TerminalDisplay.width(
                of: glyph
               ) == 1 {
                for column in stride(
                    from: 0,
                    to: leadingColumns,
                    by: max(
                        1,
                        options.width
                    )
                ).reversed() {
                    let before = column > 0
                        ? TerminalDisplay.slice(
                            content,
                            columns: 0..<column
                        )
                        : ""
                    let after = column + 1 < row.columns
                        ? TerminalDisplay.slice(
                            content,
                            columns: (column + 1)..<row.columns
                        )
                        : ""

                    content = before
                        + glyph
                        + after
                }
            }
        }

        return selectionStyle.apply(
            TerminalDisplay.fitted(
                content,
                columns: columns
            )
        )
    }

    private func renderedIndentationGuides(
        in renderedContent: String,
        row: TerminalTextLayoutRow,
        options: TerminalIndentationGuideOptions,
        selectionRanges: [Range<Int>],
        selectionStyle: TerminalStyle,
        yankRanges: [Range<Int>],
        yankStyle: TerminalStyle
    ) -> String {
        guard options.isEnabled,
              row.isSourceLineStart else {
            return renderedContent
        }

        let leadingColumns = row.content.prefix {
            $0 == " "
        }.count

        guard leadingColumns > 0 else {
            return renderedContent
        }

        let glyph = TerminalDisplay.fitted(
            options.glyph,
            columns: 1
        )

        guard TerminalDisplay.width(
            of: glyph
        ) == 1 else {
            return renderedContent
        }

        var result = renderedContent
        let guideColumns = stride(
            from: 0,
            to: leadingColumns,
            by: options.width
        ).reversed()

        for column in guideColumns {
            let sourceOffset = row.sourceOffset(
                atColumn: column
            )
            let style: TerminalStyle

            if yankRanges.contains(
                where: {
                    $0.contains(
                        sourceOffset
                    )
                }
            ) {
                style = yankStyle
            } else if selectionRanges.contains(
                where: {
                    $0.contains(
                        sourceOffset
                    )
                }
            ) {
                style = selectionStyle
            } else {
                style = options.style
            }

            let before = column > 0
                ? TerminalDisplay.slice(
                    result,
                    columns: 0..<column
                )
                : ""
            let after = column + 1 < row.columns
                ? TerminalDisplay.slice(
                    result,
                    columns: (column + 1)..<row.columns
                )
                : ""

            result = before
                + style.apply(
                    glyph
                )
                + after
        }

        return result
    }

    private func range(
        _ range: Range<Int>,
        touches row: TerminalTextLayoutRow
    ) -> Bool {
        row.sourceRange.overlaps(
            range
        )
            || (
                row.sourceRange.isEmpty
                && range.contains(
                    row.sourceRange.lowerBound
                )
            )
    }
}
