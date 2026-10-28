import Foundation
import ReSwift

struct MouseLocationState: Equatable {
    var isWithinScreen = false
}

func mouseLocationReducer(action: Action, state: MouseLocationState) -> MouseLocationState {
    switch action {
    case let MouseLocationAction.located(isWithinScreen):
        return MouseLocationState(isWithinScreen: isWithinScreen)

    default:
        return state
    }
}
