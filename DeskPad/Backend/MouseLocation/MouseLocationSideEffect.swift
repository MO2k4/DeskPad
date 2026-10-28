import Foundation
import ReSwift

enum MouseLocationAction: Action {
    case located(isWithinScreen: Bool)
    case requestMove(toPoint: NSPoint)
}

let mouseLocationSideEffect: SideEffect = { dispatch, getState in
    Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        let screenContainingMouse = (screens.first { NSMouseInRect(mouseLocation, $0.frame, false) })
        let isWithinScreen = screenContainingMouse?.displayID == getState()?.screenConfigurationState.displayID
        dispatch(MouseLocationAction.located(isWithinScreen: isWithinScreen))
    }
    return { action in
        guard
            case let MouseLocationAction.requestMove(point) = action,
            let displayID = getState()?.screenConfigurationState.displayID
        else {
            return
        }
        CGDisplayMoveCursorToPoint(displayID, point)
    }
}
