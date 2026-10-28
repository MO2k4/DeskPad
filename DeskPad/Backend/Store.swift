import Foundation
import ReSwift

let store = Store<AppState>(
    reducer: appReducer,
    state: AppState(),
    middleware: [
        sideEffectsMiddleware,
    ]
)
