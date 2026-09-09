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
}
