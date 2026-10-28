import ReSwift

struct AppState: Equatable {
    var mouseLocationState = MouseLocationState()
    var screenConfigurationState = ScreenConfigurationState()
}

func appReducer(action: Action, state: AppState?) -> AppState {
    let state = state ?? AppState()

    return AppState(
        mouseLocationState: mouseLocationReducer(action: action, state: state.mouseLocationState),
        screenConfigurationState: screenConfigurationReducer(action: action, state: state.screenConfigurationState)
    )
}
