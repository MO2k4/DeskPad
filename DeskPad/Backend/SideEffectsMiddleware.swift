import Foundation
import ReSwift

/// Called once when the store is set up; returns a handler that receives every action after the reducer.
typealias SideEffect = (@escaping DispatchFunction, @escaping () -> AppState?) -> (Action) -> Void

let sideEffectsMiddleware: Middleware<AppState> = { dispatch, getState in
    let handlers = [
        mouseLocationSideEffect,
        screenConfigurationSideEffect,
    ].map { $0(dispatch, getState) }
    return { originalDispatch in
        { action in
            originalDispatch(action)
            for handler in handlers {
                handler(action)
            }
        }
    }
}
