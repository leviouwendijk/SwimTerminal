import Swim
import SwimInterpreter

public enum SwimTerminalSurfaceEvent:
    Sendable,
    Codable,
    Hashable
{
    case changed
    case copyRequested(SwimEditorCopy)
    case commandRequested(SwimInterpreter.ExCommand)
    case invalidCommand(String)
    case cancelRequested
    case rejected(SwimEditorRejection)
}
