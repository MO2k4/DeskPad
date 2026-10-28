import Foundation
import ReSwift

private var timer: Timer?

enum MouseLocationAction: Action {
    case located(isWithinScreen: Bool)
    case requestMove(toPoint: NSPoint)
}

func mouseLocationSideEffect() -> SideEffect {
    return { action, dispatch, getState in
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                let mouseLocation = NSEvent.mouseLocation
                let screens = NSScreen.screens
                let screenContainingMouse = (screens.first { NSMouseInRect(mouseLocation, $0.frame, false) })
                let isWithinScreen = screenContainingMouse?.displayID == getState()?.screenConfigurationState.displayID
                guard isWithinScreen != getState()?.mouseLocationState.isWithinScreen else {
                    return
                }
                dispatch(MouseLocationAction.located(isWithinScreen: isWithinScreen))
            }
            // Lets the system coalesce this wakeup with others; highlight latency isn't critical.
            timer?.tolerance = 0.1
        }
        switch action {
        case let MouseLocationAction.requestMove(point):
            guard let displayID = getState()?.screenConfigurationState.displayID else {
                return
            }
            CGDisplayMoveCursorToPoint(displayID, point)
        default:
            return
        }
    }
}
