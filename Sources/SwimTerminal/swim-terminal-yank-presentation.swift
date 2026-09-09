import Swim
import SwimInterpreter

public struct SwimTerminalYankPresentation:
    Sendable,
    Hashable
{
    public static let standardDurationNanoseconds: UInt64 =
        200_000_000

    public let sourceRanges: [Range<Int>]
    public let kind: SwimInterpreter.SelectionKind
    public let expiresAtNanoseconds: UInt64

    public init(
        copy: SwimEditorCopy,
        startedAtNanoseconds: UInt64,
        durationNanoseconds: UInt64 =
            SwimTerminalYankPresentation.standardDurationNanoseconds
    ) {
        let (
            expiration,
            overflow
        ) = startedAtNanoseconds.addingReportingOverflow(
            durationNanoseconds
        )

        sourceRanges = copy.sourceRanges.map { range in
            range.offsets
        }
        kind = copy.value.kind
        expiresAtNanoseconds = overflow
            ? UInt64.max
            : expiration
    }

    public var sourceRange: Range<Int> {
        sourceRanges.first
            ?? 0..<0
    }

    public func isActive(
        atNanoseconds now: UInt64
    ) -> Bool {
        now < expiresAtNanoseconds
    }
}
