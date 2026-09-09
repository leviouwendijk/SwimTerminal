public enum SwimTerminalYankClipboardPolicy:
    Sendable,
    Codable,
    Hashable
{
    case systemClipboard
    case registerOnly
}

public struct SwimTerminalConfiguration:
    Sendable,
    Codable,
    Hashable
{
    public var yankClipboardPolicy: SwimTerminalYankClipboardPolicy
    public var tabWidth: Int

    public init(
        yankClipboardPolicy: SwimTerminalYankClipboardPolicy = .systemClipboard,
        tabWidth: Int = 4
    ) {
        self.yankClipboardPolicy = yankClipboardPolicy
        self.tabWidth = max(
            1,
            tabWidth
        )
    }
}
