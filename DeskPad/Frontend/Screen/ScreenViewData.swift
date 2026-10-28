import Foundation

struct ScreenViewData: ViewDataType {
    static func fragment(of appState: AppState) -> AppState {
        return appState
    }

    let isWindowHighlighted: Bool
    let resolution: CGSize
    let scaleFactor: CGFloat

    init(for state: AppState) {
        isWindowHighlighted = state.mouseLocationState.isWithinScreen
        resolution = state.screenConfigurationState.resolution
        scaleFactor = state.screenConfigurationState.scaleFactor
    }
}
