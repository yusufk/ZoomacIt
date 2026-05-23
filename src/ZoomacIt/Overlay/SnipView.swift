import AppKit
import CoreGraphics

/// Displays a frozen screenshot and lets the user drag-select a region.
final class SnipView: NSView {

    var onDismiss: (() -> Void)?
    var onSnip: ((CGImage) -> Void)?

    private let sourceImage: CGImage
    private let scaleFactor: CGFloat
    private var selectionRect: NSRect = .zero
    private var dragStart: NSPoint = .zero
    private var isDragging = false

    init(frame: NSRect, sourceImage: CGImage, scaleFactor: CGFloat) {
        self.sourceImage = sourceImage
        self.scaleFactor = scaleFactor
        super.init(frame: frame)
        wantsLayer = true
        layer?.contents = sourceImage
        layer?.contentsGravity = .resizeAspectFill
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.invalidateCursorRects(for: self)
    }

    override func resetCursorRects() {
        discardCursorRects()
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func mouseMoved(with event: NSEvent) {
        NSCursor.crosshair.set()
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard isDragging, selectionRect.width > 0, selectionRect.height > 0 else { return }

        // Dim everything outside selection
        NSColor.black.withAlphaComponent(0.4).setFill()
        dirtyRect.fill()

        // Clear the selection area (show original image through)
        let path = NSBezierPath(rect: selectionRect)
        NSGraphicsContext.current?.compositingOperation = .clear
        path.fill()

        // Draw selection border
        NSGraphicsContext.current?.compositingOperation = .sourceOver
        NSColor.white.setStroke()
        let border = NSBezierPath(rect: selectionRect)
        border.lineWidth = 1.5
        border.stroke()
    }

    // MARK: - Mouse

    override func mouseDown(with event: NSEvent) {
        dragStart = convert(event.locationInWindow, from: nil)
        selectionRect = .zero
        isDragging = true
    }

    override func mouseDragged(with event: NSEvent) {
        let current = convert(event.locationInWindow, from: nil)
        selectionRect = NSRect(
            x: min(dragStart.x, current.x),
            y: min(dragStart.y, current.y),
            width: abs(current.x - dragStart.x),
            height: abs(current.y - dragStart.y)
        )
        setNeedsDisplay(bounds)
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
        guard selectionRect.width > 2, selectionRect.height > 2 else {
            onDismiss?()
            return
        }

        // Convert view coords to image pixel coords
        let cropRect = CGRect(
            x: selectionRect.origin.x * scaleFactor,
            y: (bounds.height - selectionRect.origin.y - selectionRect.height) * scaleFactor,
            width: selectionRect.width * scaleFactor,
            height: selectionRect.height * scaleFactor
        ).integral

        if let cropped = sourceImage.cropping(to: cropRect) {
            onSnip?(cropped)
        } else {
            onDismiss?()
        }
    }

    // MARK: - Keyboard

    override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers == "\u{1B}" { // Escape
            onDismiss?()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        onDismiss?()
    }
}
