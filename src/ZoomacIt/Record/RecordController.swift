import AppKit
import AVFoundation
import CoreMedia
import ScreenCaptureKit

/// Error types for recording failures.
enum RecordError: Error {
    case displayNotFound
    case permissionDenied
    case writerSetupFailed
}

/// Manages full-screen recording via SCStream → AVAssetWriter.
@MainActor
final class RecordController: NSObject {

    var onRecordingStarted: (() -> Void)?
    var onRecordingStopped: ((URL) -> Void)?
    var onRecordingFailed: ((Error) -> Void)?

    private(set) var isRecording = false
    private var stream: SCStream?
    private var streamOutput: RecordStreamOutput?
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var startTime: CMTime?
    private var outputURL: URL?
    private var indicatorWindow: NSWindow?

    // MARK: - Public

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func startRecording() {
        guard !isRecording else { return }
        guard CGPreflightScreenCaptureAccess() else {
            NSLog("[RecordController] Screen Recording permission denied")
            onRecordingFailed?(RecordError.permissionDenied)
            return
        }

        let screen = NSScreen.main ?? NSScreen.screens[0]
        let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? CGMainDisplayID()
        let scaleFactor = screen.backingScaleFactor

        Task {
            do {
                try await setupAndStart(displayID: displayID, scaleFactor: scaleFactor, screenSize: screen.frame.size)
            } catch {
                NSLog("[RecordController] Failed to start recording: %@", error.localizedDescription)
                onRecordingFailed?(error)
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        hideIndicator()

        stream?.stopCapture { _ in }
        stream = nil
        streamOutput = nil

        videoInput?.markAsFinished()
        assetWriter?.finishWriting { [weak self] in
            guard let self, let url = self.outputURL else { return }
            DispatchQueue.main.async {
                NSLog("[RecordController] Recording saved: %@", url.path)
                self.onRecordingStopped?(url)
            }
        }
    }

    // MARK: - Private

    private func setupAndStart(displayID: CGDirectDisplayID, scaleFactor: CGFloat, screenSize: CGSize) async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
            throw RecordError.displayNotFound
        }

        // Exclude our own indicator window
        let myPID = ProcessInfo.processInfo.processIdentifier
        let excludedWindows = content.windows.filter { $0.owningApplication?.processID == myPID }

        let filter = SCContentFilter(display: display, excludingWindows: excludedWindows)
        let config = SCStreamConfiguration()
        let width = Int(screenSize.width * scaleFactor)
        let height = Int(screenSize.height * scaleFactor)
        config.width = width
        config.height = height
        config.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = true
        config.queueDepth = 5

        // Setup AVAssetWriter
        let url = outputFileURL()
        outputURL = url
        try? FileManager.default.removeItem(at: url)

        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        input.expectsMediaDataInRealTime = true
        let pixelAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
        )
        writer.add(input)
        guard writer.startWriting() else {
            throw RecordError.writerSetupFailed
        }
        writer.startSession(atSourceTime: .zero)

        self.assetWriter = writer
        self.videoInput = input
        self.adaptor = pixelAdaptor
        self.startTime = nil

        // Setup stream output
        let output = RecordStreamOutput { [weak self] sampleBuffer in
            self?.handleFrame(sampleBuffer)
        }
        self.streamOutput = output

        let newStream = SCStream(filter: filter, configuration: config, delegate: nil)
        let captureQueue = DispatchQueue(label: "com.zoomacit.record.capture", qos: .userInteractive)
        try newStream.addStreamOutput(output, type: .screen, sampleHandlerQueue: captureQueue)
        try await newStream.startCapture()
        self.stream = newStream
        self.isRecording = true

        showIndicator()
        onRecordingStarted?()
        NSLog("[RecordController] Recording started at %dx%d", width, height)
    }

    private func handleFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = sampleBuffer.imageBuffer,
              let input = videoInput, input.isReadyForMoreMediaData else { return }

        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        if startTime == nil {
            startTime = timestamp
        }
        let relativeTime = CMTimeSubtract(timestamp, startTime!)
        adaptor?.append(pixelBuffer, withPresentationTime: relativeTime)
    }

    private func outputFileURL() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        let name = "ZoomacIt Recording \(formatter.string(from: Date())).mp4"
        return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
    }

    // MARK: - Recording Indicator

    private func showIndicator() {
        let frame = NSRect(x: 8, y: 8, width: 12, height: 12)
        let window = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        let dot = NSView(frame: NSRect(x: 0, y: 0, width: 12, height: 12))
        dot.wantsLayer = true
        dot.layer?.backgroundColor = NSColor.red.cgColor
        dot.layer?.cornerRadius = 6
        window.contentView = dot
        window.orderFront(nil)
        indicatorWindow = window
    }

    private func hideIndicator() {
        indicatorWindow?.orderOut(nil)
        indicatorWindow = nil
    }
}

// MARK: - Stream Output Handler

final class RecordStreamOutput: NSObject, SCStreamOutput, @unchecked Sendable {
    private let handler: (CMSampleBuffer) -> Void

    init(handler: @escaping (CMSampleBuffer) -> Void) {
        self.handler = handler
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        handler(sampleBuffer)
    }
}
