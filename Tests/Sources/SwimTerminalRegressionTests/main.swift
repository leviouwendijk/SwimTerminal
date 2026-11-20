import Foundation
import SwimTerminal
import Terminal
import Testing

private enum RegressionFailure: Error {
    case failed
}

// Check mappings as well as rendered strings: wrapping must not lose source
// characters or leave cursor offsets pointing at their pre-wrap positions.
private func checkMappings(_ layout: TerminalTextLayout) throws {
    for (rowIndex, row) in layout.rows.enumerated() {
        try Expect.true(
            TerminalDisplay.width(of: row.content) <= layout.columns,
            "row fits available columns"
        )
        for offset in row.sourceRange {
            let position = layout.position(forCursorOffset: offset)
            try Expect.equal(position.row, rowIndex, "cursor row")
            try Expect.equal(
                position.column,
                row.columnOffsets[offset - row.sourceRange.lowerBound],
                "cursor column"
            )
        }
    }
}

let suite = TestSuite("terminal wrapping regressions") {
    Test("character wrapping remains the default") { _ in
        let layout = TerminalTextLayout(text: "ab cdef", columns: 5)
        try Expect.equal(layout.rows.map(\.content), ["ab cd", "ef"], "default rows")
        try checkMappings(layout)
    }

    Test("word wrapping preserves spaces and source ranges") { _ in
        let layout = TerminalTextLayout(text: "ab cdef", columns: 5, wrapMode: .word)
        try Expect.equal(layout.rows.map(\.content), ["ab ", "cdef"], "word rows")
        try Expect.equal(layout.rows.map(\.sourceRange), [0..<3, 3..<7], "source coverage")
        try checkMappings(layout)
    }

    Test("long words fall back to character wrapping") { _ in
        let layout = TerminalTextLayout(text: "abcdefgh", columns: 3, wrapMode: .word)
        try Expect.equal(layout.rows.map(\.content), ["abc", "def", "gh"], "fallback rows")
        try checkMappings(layout)
    }

    Test("tabs are break points") { _ in
        let layout = TerminalTextLayout(text: "a b\tcd", columns: 5, tabWidth: 4, wrapMode: .word)
        try Expect.equal(layout.rows.map(\.content), ["a b ", "cd"], "tab rows")
        try Expect.equal(layout.rows.map(\.sourceRange), [0..<4, 4..<6], "tab source coverage")
        try checkMappings(layout)
    }

    Test("a word ending at the edge keeps its row") { _ in
        let exact = TerminalTextLayout(text: "hello world foo", columns: 11, wrapMode: .word)
        try Expect.equal(exact.rows.map(\.content), ["hello world", "foo"], "full row kept")
        try Expect.equal(exact.rows.map(\.sourceRange), [0..<12, 12..<15], "blank hangs on the full row")
        try checkMappings(exact)
        let blanks = TerminalTextLayout(text: "hello   world", columns: 5, wrapMode: .word)
        try Expect.equal(blanks.rows.map(\.content), ["hello", "world"], "no blank-only row")
        try checkMappings(blanks)
    }

    Test("a hanging blank before a newline adds no row") { _ in
        let layout = TerminalTextLayout(text: "hello \nx", columns: 5, wrapMode: .word)
        try Expect.equal(layout.rows.map(\.content), ["hello", "x"], "newline rows")
        try checkMappings(layout)
    }

    Test("leading indentation is not a break point") { _ in
        let layout = TerminalTextLayout(text: "    indented", columns: 6, wrapMode: .word)
        try Expect.equal(layout.rows.map(\.content), ["    in", "dented"], "indented rows")
        try checkMappings(layout)
    }

    Test("wide characters and explicit newlines preserve mappings") { _ in
        let layout = TerminalTextLayout(text: "a 界界\nz", columns: 4, wrapMode: .word)
        try Expect.equal(layout.rows.map(\.content), ["a ", "界界", "z"], "wide rows")
        try Expect.equal(layout.rows.map(\.sourceLineNumber), [1, 1, 2], "source line numbers")
        try Expect.equal(layout.rows.map(\.isSourceLineStart), [true, false, true], "line starts")
        try checkMappings(layout)
    }

    Test("narrow columns and oversized tabs remain bounded") { _ in
        for columns in 1...8 {
            for tabWidth in [1, 4, 8] {
                for mode in [TerminalTextWrapMode.character, .word] {
                    for text in ["", "\n", "a b\tcdef", "ab\tcd ef", "界 a\t界\nlast "] {
                        try checkMappings(TerminalTextLayout(
                            text: text,
                            columns: columns,
                            tabWidth: tabWidth,
                            wrapMode: mode
                        ))
                    }
                }
            }
        }
    }

    Test("configuration defaults to word wrapping, also when decoding") { _ in
        try Expect.equal(SwimTerminalConfiguration().wrapMode, .word, "default mode")
        let legacy = Data(#"{"yankClipboardPolicy":{"registerOnly":{}},"tabWidth":4}"#.utf8)
        let decoded = try JSONDecoder().decode(SwimTerminalConfiguration.self, from: legacy)
        try Expect.equal(decoded.wrapMode, .word, "legacy mode")
        try Expect.equal(decoded.yankClipboardPolicy, .registerOnly, "legacy clipboard policy")
    }

    Test("wrap configuration round trips") { _ in
        let configuration = SwimTerminalConfiguration(tabWidth: 8, wrapMode: .character)
        let data = try JSONEncoder().encode(configuration)
        let decoded = try JSONDecoder().decode(SwimTerminalConfiguration.self, from: data)
        try Expect.equal(decoded, configuration, "configuration round trip")
    }
}

let result = await TestRunner.run(suite)
print(String(describing: result))
if result.isFailure {
    throw RegressionFailure.failed
}
