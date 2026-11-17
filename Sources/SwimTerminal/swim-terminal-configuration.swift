import Terminal

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
    public var wrapMode: TerminalTextWrapMode

    public init(
        yankClipboardPolicy: SwimTerminalYankClipboardPolicy = .systemClipboard,
        tabWidth: Int = 4,
        wrapMode: TerminalTextWrapMode = .character
    ) {
        self.yankClipboardPolicy = yankClipboardPolicy
        self.tabWidth = max(1, tabWidth)
        self.wrapMode = wrapMode
    }

    private enum CodingKeys: String, CodingKey {
        case yankClipboardPolicy
        case tabWidth
        case wrapMode
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            yankClipboardPolicy: try container.decode(
                SwimTerminalYankClipboardPolicy.self,
                forKey: .yankClipboardPolicy
            ),
            tabWidth: try container.decode(Int.self, forKey: .tabWidth),
            wrapMode: try container.decodeIfPresent(
                TerminalTextWrapMode.self,
                forKey: .wrapMode
            ) ?? .character
        )
    }
}
