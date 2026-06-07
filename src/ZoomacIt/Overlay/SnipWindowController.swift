import AppKit
import ScreenCaptureKit

/// Controls Snip mode — capture screen, select region, copy to clipboard.
@MainActor
final class SnipWindowController {

    var onDismiss: (() -> Void)?
    var onShowFailed: (() -> Void)?
    var saveToFile: Bool = false

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
            if self?.saveToFile == true {
                Self.saveToDesktop(croppedImage)
                NSLog("[SnipWindowController] Snip saved to Desktop")
            } else {
                Self.copyToClipboard(croppedImage)
                Self.showSnipThumbnail(image: croppedImage, fileURL: nil)
                NSLog("[SnipWindowController] Snip copied to clipboard")
            }
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

    private static func saveToDesktop(_ image: CGImage) {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let url = desktop.appendingPathComponent("ZoomacIt-\(timestamp).png")
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else { return }
        CGImageDestinationAddImage(dest, image, nil)
        CGImageDestinationFinalize(dest)
        showSnipThumbnail(image: image, fileURL: url)
    }

    private static func showSnipThumbnail(image: CGImage, fileURL: URL?) {
        guard let screen = NSScreen.main else { return }
        let thumbSize: CGFloat = 160
        let padding: CGFloat = 20
        let frame = NSRect(
            x: screen.visibleFrame.maxX - thumbSize - padding,
            y: screen.visibleFrame.minY + padding,
            width: thumbSize,
            height: thumbSize
        )

        let window = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = true
        window.isReleasedWhenClosed = false

        let clickView = SnipThumbnailView(frame: NSRect(origin: .zero, size: frame.size), image: image, fileURL: fileURL)
        clickView.onClose = { window.close() }

        window.contentView = clickView
        window.orderFrontRegardless()

        // Fade out after 4 seconds (cancelled if user right-clicks)
        let fadeWork = DispatchWorkItem { [weak window] in
            guard let window else { return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.5
                window.animator().alphaValue = 0
            }, completionHandler: {
                window.close()
            })
        }
        clickView.cancelFade = { fadeWork.cancel() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: fadeWork)
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

// MARK: - Clickable Thumbnail

private final class SnipThumbnailView: NSView {
    var onClose: (() -> Void)?
    var cancelFade: (() -> Void)?
    private let fileURL: URL?
    private let snipImage: CGImage

    init(frame: NSRect, image: CGImage, fileURL: URL? = nil) {
        self.fileURL = fileURL
        self.snipImage = image
        super.init(frame: frame)
        wantsLayer = true
        layer?.contents = image
        layer?.contentsGravity = .resizeAspect
        layer?.cornerRadius = 8
        layer?.masksToBounds = true
        layer?.borderColor = NSColor.white.withAlphaComponent(0.8).cgColor
        layer?.borderWidth = 2
        menu = buildContextMenu()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func mouseDown(with event: NSEvent) {
        if let fileURL {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        }
        onClose?()
    }

    override func rightMouseDown(with event: NSEvent) {
        cancelFade?()
        menu = buildContextMenu()
        super.rightMouseDown(with: event)
    }

    private func buildContextMenu() -> NSMenu {
        let menu = NSMenu()
        let aiAvailable = Settings.shared.aiEnabled && GeminiService.shared.isAvailable

        let extractText = NSMenuItem(title: "Extract Text", action: #selector(extractTextAction), keyEquivalent: "")
        extractText.target = self
        extractText.isEnabled = aiAvailable
        menu.addItem(extractText)

        let translate = NSMenuItem(title: "Translate Text", action: #selector(translateAction), keyEquivalent: "")
        translate.target = self
        translate.isEnabled = aiAvailable
        menu.addItem(translate)

        let searchText = NSMenuItem(title: "Search Text", action: #selector(searchTextAction), keyEquivalent: "")
        searchText.target = self
        searchText.isEnabled = aiAvailable
        menu.addItem(searchText)

        menu.addItem(.separator())

        let imageSearch = NSMenuItem(title: "Image Search", action: #selector(imageSearchAction), keyEquivalent: "")
        imageSearch.target = self
        imageSearch.isEnabled = aiAvailable
        menu.addItem(imageSearch)

        let findObjects = NSMenuItem(title: "Find Objects", action: #selector(findObjectsAction), keyEquivalent: "")
        findObjects.target = self
        findObjects.isEnabled = aiAvailable
        menu.addItem(findObjects)

        let reframe = NSMenuItem(title: "Smart Reframe", action: #selector(smartReframeAction), keyEquivalent: "")
        reframe.target = self
        reframe.isEnabled = aiAvailable
        menu.addItem(reframe)

        menu.addItem(.separator())

        let copy = NSMenuItem(title: "Copy Image", action: #selector(copyImageAction), keyEquivalent: "c")
        copy.target = self
        menu.addItem(copy)

        return menu
    }

    // MARK: - AI Actions

    @objc private func extractTextAction() {
        runAITask(.extractText) { result in
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(result.text, forType: .string)
            self.showResultToast("Text copied to clipboard")
        }
    }

    @objc private func translateAction() {
        runAITask(.translate(to: "English")) { result in
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(result.text, forType: .string)
            self.showResultToast("Translation copied to clipboard")
        }
    }

    @objc private func searchTextAction() {
        runAITask(.extractText) { result in
            guard !result.text.isEmpty,
                  let query = result.text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: "https://www.google.com/search?q=\(query)") else { return }
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func imageSearchAction() {
        // Save temp image and open Google Lens
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("zoomacit-search.png")
        guard let dest = CGImageDestinationCreateWithURL(tempURL as CFURL, "public.png" as CFString, 1, nil) else { return }
        CGImageDestinationAddImage(dest, snipImage, nil)
        CGImageDestinationFinalize(dest)
        // Use Google Lens upload page
        if let url = URL(string: "https://lens.google.com") {
            NSWorkspace.shared.open(url)
        }
        // Also copy to clipboard for easy paste
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([NSImage(cgImage: snipImage, size: NSSize(width: snipImage.width, height: snipImage.height))])
        showResultToast("Image copied — paste into Google Lens")
    }

    @objc private func findObjectsAction() {
        runAITask(.detectObjects) { result in
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(result.text, forType: .string)
            self.showResultToast("Objects: \(result.boxes?.count ?? 0) found")
        }
    }

    @objc private func smartReframeAction() {
        runAITask(.smartReframe) { result in
            guard let box = result.boxes?.first else {
                self.showResultToast("No subject detected")
                return
            }
            let w = CGFloat(self.snipImage.width)
            let h = CGFloat(self.snipImage.height)
            let cropRect = CGRect(
                x: box.x * Double(w), y: box.y * Double(h),
                width: box.width * Double(w), height: box.height * Double(h)
            )
            if let cropped = self.snipImage.cropping(to: cropRect) {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.writeObjects([NSImage(cgImage: cropped, size: NSSize(width: cropped.width, height: cropped.height))])
                self.showResultToast("Reframed image copied")
            }
        }
    }

    @objc private func copyImageAction() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([NSImage(cgImage: snipImage, size: NSSize(width: snipImage.width, height: snipImage.height))])
        onClose?()
    }

    // MARK: - Helpers

    private func runAITask(_ task: GeminiService.AITask, completion: @escaping (GeminiService.AIResult) -> Void) {
        showResultToast("Analyzing...")
        Task { @MainActor in
            do {
                let result = try await GeminiService.shared.analyze(image: snipImage, task: task)
                completion(result)
            } catch {
                showResultToast("Error: \(error.localizedDescription)")
            }
        }
    }

    private func showResultToast(_ message: String) {
        // Brief tooltip-style feedback
        let alert = NSAlert()
        alert.messageText = "ZoomacIt AI"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
