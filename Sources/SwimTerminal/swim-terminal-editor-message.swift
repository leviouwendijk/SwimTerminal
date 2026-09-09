import Swim

public enum SwimTerminalEditorMessage {
    public static func text(
        for rejection: SwimEditorRejection
    ) -> String {
        switch rejection.reason {
        case .bufferNonmodifiable:
            return "E21: Cannot make changes, 'modifiable' is off"
        }
    }

    public static func text(
        forInvalidCommand command: String
    ) -> String {
        command.isEmpty
            ? "E492: Not an editor command"
            : "E492: Not an editor command: \(command)"
    }
}
