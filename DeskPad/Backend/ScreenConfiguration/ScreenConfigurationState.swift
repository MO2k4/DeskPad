import Foundation
import ReSwift

struct ScreenConfigurationState: Equatable {
    var resolution: CGSize = .zero
    var scaleFactor: CGFloat = 1
    var displayID: CGDirectDisplayID?
}

func screenConfigurationReducer(action: Action, state: ScreenConfigurationState) -> ScreenConfigurationState {
    var state = state
    switch action {
    case let ScreenConfigurationAction.set(resolution, scaleFactor):
        state.resolution = resolution
        state.scaleFactor = scaleFactor
    case let ScreenViewAction.setDisplayID(displayID):
        state.displayID = displayID
    default:
        break
    }
    return state
}
