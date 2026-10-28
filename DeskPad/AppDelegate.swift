import Cocoa

private let lockWindowSizeKey = "lockWindowSize"

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_: Notification) {
        let viewController = ScreenViewController()
        window = NSWindow(contentViewController: viewController)
        window.delegate = viewController
        window.title = "DeskPad"
        window.makeKeyAndOrderFront(nil)
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.titleVisibility = .hidden
        window.backgroundColor = .white
        window.contentMinSize = CGSize(width: 400, height: 300)
        window.contentMaxSize = CGSize(width: 5120, height: 2160)
        let isSizeLocked = UserDefaults.standard.bool(forKey: lockWindowSizeKey)
        if !isSizeLocked {
            window.styleMask.insert(.resizable)
        }
        window.collectionBehavior.insert(.fullScreenNone)

        let mainMenu = NSMenu()
        let mainMenuItem = NSMenuItem()
        let subMenu = NSMenu(title: "MainMenu")
        let lockSizeMenuItem = NSMenuItem(
            title: "Lock Window Size",
            action: #selector(toggleWindowSizeLock),
            keyEquivalent: "l"
        )
        lockSizeMenuItem.target = self
        lockSizeMenuItem.state = isSizeLocked ? .on : .off
        subMenu.addItem(lockSizeMenuItem)
        let quitMenuItem = NSMenuItem(
            title: "Quit",
            action: #selector(NSApp.terminate),
            keyEquivalent: "q"
        )
        subMenu.addItem(quitMenuItem)
        mainMenuItem.submenu = subMenu
        mainMenu.items = [mainMenuItem]
        NSApplication.shared.mainMenu = mainMenu
    }

    @objc private func toggleWindowSizeLock(_ sender: NSMenuItem) {
        window.styleMask.formSymmetricDifference(.resizable)
        let isSizeLocked = !window.styleMask.contains(.resizable)
        sender.state = isSizeLocked ? .on : .off
        UserDefaults.standard.set(isSizeLocked, forKey: lockWindowSizeKey)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }
}
