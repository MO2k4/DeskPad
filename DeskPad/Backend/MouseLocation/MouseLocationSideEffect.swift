import Foundation
import ReSwift

enum MouseLocationAction: Action {
    case located(isWithinScreen: Bool)
    case requestMove(toPoint: NSPoint)
}

let mouseLocationSideEffect: SideEffect = { dispatch, getState in
    let timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
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
    timer.tolerance = 0.1
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
