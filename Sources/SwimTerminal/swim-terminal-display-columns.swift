import Swim
import Terminal

public struct SwimTerminalDisplayColumnMappingProvider:
    SwimDisplayColumnMappingProviding,
    Sendable
{
    public let tabWidth: Int

    public init(
        tabWidth: Int = 4
    ) {
        self.tabWidth = max(
            1,
            tabWidth
        )
    }

    public func mapping(
        for text: String
    ) -> any SwimDisplayColumnMapping {
        SwimHeadlessDisplayColumnMapping(
            text: text,
            tabWidth: tabWidth
        ) { character in
            TerminalDisplay.width(
                of: String(
                    character
                )
            )
        }
    }
}
