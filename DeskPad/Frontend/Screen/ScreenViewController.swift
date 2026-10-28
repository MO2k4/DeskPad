import Cocoa
import ScreenCaptureKit

class ScreenViewController: NSViewController, NSWindowDelegate, SCStreamOutput, SCStreamDelegate {
    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(didClickOnScreen)))
    }

    private var display: CGVirtualDisplay!
    private var stream: SCStream?
    private var streamStartTask: Task<Void, Never>?
    private var isWindowHighlighted = false
    private var previousResolution: CGSize?
    private var previousScaleFactor: CGFloat?

    override func viewDidLoad() {
        super.viewDidLoad()

        let descriptor = CGVirtualDisplayDescriptor()
        descriptor.setDispatchQueue(DispatchQueue.main)
        descriptor.name = "DeskPad Display"
        descriptor.maxPixelsWide = 5120
        descriptor.maxPixelsHigh = 2160
        descriptor.sizeInMillimeters = CGSize(width: 1600, height: 1000)
        descriptor.productID = 0x1234
        descriptor.vendorID = 0x3456
        descriptor.serialNum = 0x0001

        let display = CGVirtualDisplay(descriptor: descriptor)
        self.display = display

        // Registered before apply(), which triggers the notification carrying the initial resolution.
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: NSApplication.shared,
            queue: .main
        ) { [weak self] _ in
            self?.screenParametersDidChange()
        }
        let mouseTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.updateWindowHighlight()
        }
        // Lets the system coalesce this wakeup with others; highlight latency isn't critical.
        mouseTimer.tolerance = 0.1

        let settings = CGVirtualDisplaySettings()
        settings.hiDPI = 1
        settings.modes = [
            // 32:9
            CGVirtualDisplayMode(width: 5120, height: 1440, refreshRate: 60),
            // 21:9 (239:100, 12:5)
            CGVirtualDisplayMode(width: 5120, height: 2160, refreshRate: 60),
            CGVirtualDisplayMode(width: 3840, height: 1600, refreshRate: 60),
            CGVirtualDisplayMode(width: 3440, height: 1440, refreshRate: 60),
            // 16:9
            CGVirtualDisplayMode(width: 3840, height: 2160, refreshRate: 60),
            CGVirtualDisplayMode(width: 2560, height: 1440, refreshRate: 60),
            CGVirtualDisplayMode(width: 1920, height: 1080, refreshRate: 60),
            CGVirtualDisplayMode(width: 1600, height: 900, refreshRate: 60),
            CGVirtualDisplayMode(width: 1366, height: 768, refreshRate: 60),
            CGVirtualDisplayMode(width: 1280, height: 720, refreshRate: 60),
            // 16:10
            CGVirtualDisplayMode(width: 2560, height: 1600, refreshRate: 60),
            CGVirtualDisplayMode(width: 1920, height: 1200, refreshRate: 60),
            CGVirtualDisplayMode(width: 1680, height: 1050, refreshRate: 60),
            CGVirtualDisplayMode(width: 1440, height: 900, refreshRate: 60),
            CGVirtualDisplayMode(width: 1280, height: 800, refreshRate: 60),
        ]
        display.apply(settings)
    }

    private func updateWindowHighlight() {
        let mouseLocation = NSEvent.mouseLocation
        let screenContainingMouse = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
        let isWithinScreen = screenContainingMouse?.displayID == display.displayID
        guard isWithinScreen != isWindowHighlighted else {
            return
        }
        isWindowHighlighted = isWithinScreen
        view.window?.backgroundColor = isWindowHighlighted
            ? NSColor(named: "TitleBarActive")
            : NSColor(named: "TitleBarInactive")
        if isWindowHighlighted {
            view.window?.orderFrontRegardless()
        }
    }

    private func screenParametersDidChange() {
        guard let screen = NSScreen.screens.first(where: { $0.displayID == display.displayID }) else {
            return
        }
        let resolution = screen.frame.size
        let scaleFactor = screen.backingScaleFactor
        guard resolution != previousResolution || scaleFactor != previousScaleFactor else {
            return
        }
        previousResolution = resolution
        previousScaleFactor = scaleFactor
        view.window?.setContentSize(resolution)
        view.window?.contentAspectRatio = resolution
        view.window?.center()
        updateStream(resolution: resolution, scaleFactor: scaleFactor)
    }

    private func updateStream(resolution: CGSize, scaleFactor: CGFloat) {
        let configuration = SCStreamConfiguration()
        configuration.width = Int(resolution.width * scaleFactor)
        configuration.height = Int(resolution.height * scaleFactor)
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        configuration.showsCursor = true

        if let stream {
            stream.updateConfiguration(configuration) { error in
                if let error {
                    NSLog("DeskPad: failed to update capture configuration: \(error)")
                }
            }
            return
        }

        streamStartTask?.cancel()
        streamStartTask = Task { [weak self] in
            guard let self, let display = await self.findCapturableDisplay() else {
                return
            }
            do {
                let stream = SCStream(
                    filter: SCContentFilter(display: display, excludingWindows: []),
                    configuration: configuration,
                    delegate: self
                )
                try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
                try await stream.startCapture()
                if Task.isCancelled {
                    try? await stream.stopCapture()
                    return
                }
                self.stream = stream
            } catch {
                NSLog("DeskPad: failed to start screen capture: \(error)")
            }
        }
    }

    // A freshly created virtual display can take a moment to appear in SCShareableContent.
    private func findCapturableDisplay() async -> SCDisplay? {
        for _ in 0 ..< 20 {
            do {
                let content = try await SCShareableContent.current
                if let match = content.displays.first(where: { $0.displayID == display.displayID }) {
                    return match
                }
            } catch {
                NSLog("DeskPad: failed to query shareable content: \(error)")
                return nil
            }
            try? await Task.sleep(for: .milliseconds(250))
            if Task.isCancelled {
                return nil
            }
        }
        NSLog("DeskPad: virtual display \(display.displayID) never became capturable")
        return nil
    }

    nonisolated func stream(_: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of _: SCStreamOutputType) {
        // Idle frames (no screen change) carry no image buffer.
        guard
            let pixelBuffer = sampleBuffer.imageBuffer,
            let surface = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue()
        else {
            return
        }
        MainActor.assumeIsolated {
            view.layer?.contents = surface
        }
    }

    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        NSLog("DeskPad: screen capture stopped: \(error)")
        let stoppedStreamID = ObjectIdentifier(stream)
        DispatchQueue.main.async { [weak self] in
            if let self, let current = self.stream, ObjectIdentifier(current) == stoppedStreamID {
                self.stream = nil
            }
        }
    }

    func windowWillResize(_ window: NSWindow, to frameSize: NSSize) -> NSSize {
        let snappingOffset: CGFloat = 30
        let contentSize = window.contentRect(forFrameRect: NSRect(origin: .zero, size: frameSize)).size
        guard
            let screenResolution = previousResolution,
            abs(contentSize.width - screenResolution.width) < snappingOffset
        else {
            return frameSize
        }
        return window.frameRect(forContentRect: NSRect(origin: .zero, size: screenResolution)).size
    }

    @objc private func didClickOnScreen(_ gestureRecognizer: NSGestureRecognizer) {
        guard let screenResolution = previousResolution else {
            return
        }
        let clickedPoint = gestureRecognizer.location(in: view)
        let onScreenPoint = NSPoint(
            x: clickedPoint.x / view.frame.width * screenResolution.width,
            y: (view.frame.height - clickedPoint.y) / view.frame.height * screenResolution.height
        )
        CGDisplayMoveCursorToPoint(display.displayID, onScreenPoint)
    }
}
