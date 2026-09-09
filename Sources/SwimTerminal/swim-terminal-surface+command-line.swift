import Dispatch
import Terminal

extension SwimTerminalSurface {
    public mutating func render(
        into frame: inout TerminalFrame,
        in region: TerminalRegion,
        isFocused: Bool = true,
        atNanoseconds now: UInt64 =
            DispatchTime.now().uptimeNanoseconds
    ) {
        guard !region.isEmpty else {
            return
        }

        let commandLineRows = commandLine.hasPresentation
            ? 1
            : 0
        let editorRows = max(
            0,
            region.rows - commandLineRows
        )
        let editorRegion = TerminalRegion(
            top: region.top,
            leading: region.leading,
            rows: editorRows,
            columns: region.columns
        )

        renderEditor(
            into: &frame,
            in: editorRegion,
            isFocused:
                isFocused
                && !commandLine.isActive,
            atNanoseconds: now
        )

        guard commandLineRows > 0 else {
            return
        }

        commandLine.render(
            into: &frame,
            in: TerminalRegion(
                top: region.top + editorRows,
                leading: region.leading,
                rows: 1,
                columns: region.columns
            ),
            isFocused:
                isFocused
                && commandLine.isActive
        )
    }
}
