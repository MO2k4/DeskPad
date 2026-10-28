import Foundation
import ReSwift

enum ScreenConfigurationAction: Action {
    case set(resolution: CGSize, scaleFactor: CGFloat)
}

let screenConfigurationSideEffect: SideEffect = { dispatch, getState in
    NotificationCenter.default.addObserver(
        forName: NSApplication.didChangeScreenParametersNotification,
        object: NSApplication.shared,
        queue: .main
    ) { _ in
        guard let screen = NSScreen.screens.first(where: {
            $0.displayID == getState()?.screenConfigurationState.displayID
        }) else {
            return
        }
        dispatch(ScreenConfigurationAction.set(
            resolution: screen.frame.size,
            scaleFactor: screen.backingScaleFactor
        ))
    }
    return { _ in }
}
