import AppKit
import ScreenCaptureKit

/// Controls Snip mode — capture screen, select region, copy to clipboard.
@MainActor
final class SnipWindowController {

    var onDismiss: (() -> Void)?
    var onShowFailed: (() -> Void)?

    private var snipWindow: OverlayWindow?
    private var snipView: SnipView?

    func showSnipOverlay() {
        NSLog("[SnipWindowController] showSnipOverlay called")
        guard let screen = NSScreen.screenContainingMouse ?? NSScreen.main else {
            onShowFailed?()
            return
        }

        let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? CGMainDisplayID()
        let scaleFactor = screen.backingScaleFactor

        Task { @MainActor in
            do {
                let image = try await Self.captureScreen(displayID: displayID, screen: screen, scaleFactor: scaleFactor)
                self.presentOverlay(on: screen, image: image, scaleFactor: scaleFactor)
            } catch {
                NSLog("[SnipWindowController] Capture failed: %@", error.localizedDescription)
                self.onShowFailed?()
            }
        }
    }

    func dismiss() {
        snipWindow?.orderOut(nil)
        snipWindow?.close()
        snipWindow = nil
        snipView = nil
        onDismiss?()
    }

    private func presentOverlay(on screen: NSScreen, image: CGImage, scaleFactor: CGFloat) {
        let window = OverlayWindow(for: screen)
        let view = SnipView(frame: NSRect(origin: .zero, size: screen.frame.size),
                            sourceImage: image, scaleFactor: scaleFactor)

        view.onDismiss = { [weak self] in
            self?.dismiss()
        }
        view.onSnip = { [weak self] croppedImage in
            Self.copyToClipboard(croppedImage)
            NSLog("[SnipWindowController] Snip copied to clipboard")
            self?.dismiss()
        }

        window.contentView = view
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(view)
        NSApplication.shared.activate(ignoringOtherApps: true)

        snipWindow = window
        snipView = view
    }

    private static func copyToClipboard(_ image: CGImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        pasteboard.writeObjects([nsImage])
    }

    private static func captureScreen(displayID: CGDirectDisplayID, screen: NSScreen, scaleFactor: CGFloat) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
            throw NSError(domain: "Snip", code: 1, userInfo: [NSLocalizedDescriptionKey: "Display not found"])
        }
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.width = Int(screen.frame.width * scaleFactor)
        config.height = Int(screen.frame.height * scaleFactor)
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = false
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }
}
