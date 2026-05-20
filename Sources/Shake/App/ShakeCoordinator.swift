import AppKit
import Foundation
import QuartzCore

/// The single object that knows how to start everything and route events
/// between Capture services and Overlay state. Lifetime = whole app.
@Observable
@MainActor
final class ShakeCoordinator {
    // MARK: - Observable surface for the debug monitor
    var isMonitoring = false
    var triggerCount = 0
    var lastTriggerAt: Date?

    // MARK: - Public collaborators
    let log = DebugLog()
    let session = SelectionSession()
    let permissions = PermissionMonitor()
    let env: OverlayEnvironment

    // MARK: - Private services
    private let detector: ShakeDetector
    private let dim: DimOverlayController
    private let overlay: FollowOverlayController
    private let probe: AXProbe
    private let capturer: Capturer
    private var clicker: ClickInterceptor?

    // MARK: - Internal state
    private var lastProbeAt: TimeInterval = 0
    private let probeInterval: TimeInterval = 1.0 / 30.0

    init() {
        let env = OverlayEnvironment(session: session)
        self.env = env

        self.detector = ShakeDetector()
        self.dim = DimOverlayController()
        self.probe = AXProbe()
        self.capturer = Capturer()

        // Components plug here. Adding a new feature = appending a line.
        self.overlay = FollowOverlayController(
            env: env,
            components: [
                ElementHeader.component(env: env),
                CaptureTray.component(env: env),
            ]
        )

        wire()
    }

    func start() {
        guard !isMonitoring else { return }
        permissions.refresh()
        if !permissions.accessibilityGranted {
            permissions.requestAccessibility()
        }
        if !permissions.screenRecordingGranted {
            permissions.requestScreenRecording()
        }

        detector.start()

        let interceptor = ClickInterceptor(
            onLeftClick: { [weak self] cgPoint in
                Task { @MainActor [weak self] in
                    self?.handleClick(at: cgPoint)
                }
            },
            onRightClick: { [weak self] cgPoint in
                Task { @MainActor [weak self] in
                    self?.handleRightClick(at: cgPoint)
                }
            }
        )
        interceptor.start()
        clicker = interceptor
        clicker?.setPassThroughRect(overlay.panelCGFrame)

        isMonitoring = true
        log.info("monitoring started")
    }

    // MARK: - Wiring

    private func wire() {
        detector.onShake = { [weak self] in self?.handleShake() }
        detector.onMove = { [weak self] p in self?.handleMove(p) }

        session.onChange = { [weak self] in
            guard let self else { return }
            self.overlay.refresh()
        }

        env.removeAsset = { [weak self] asset in
            self?.session.remove(asset)
        }
        env.copyAsset = { [weak self] asset in
            self?.session.copy(asset)
        }

        overlay.onFrameChange = { [weak self] frame in
            self?.clicker?.setPassThroughRect(frame)
        }
    }

    // MARK: - Event handlers

    private func handleShake() {
        triggerCount += 1
        lastTriggerAt = Date()
        NSSound.beep()
        overlay.toggle()
        let nowVisible = overlay.isVisible
        env.overlayVisible = nowVisible
        env.overlayPinned = false
        clicker?.setEnabled(nowVisible)
        if nowVisible {
            dim.show()
            overlay.refresh()
            probeAndUpdate(at: NSEvent.mouseLocation, force: true)
        } else {
            dim.hide()
        }
        log.info("shake #\(triggerCount) overlay=\(nowVisible ? "shown" : "hidden")")
    }

    private func handleMove(_ p: NSPoint) {
        if env.overlayPinned { return }
        overlay.updatePosition(cursor: p)
        guard overlay.isVisible else { return }
        probeAndUpdate(at: p, force: false)
    }

    private func handleRightClick(at cgPoint: CGPoint) {
        guard env.overlayVisible else { return }
        env.overlayPinned.toggle()
        if !env.overlayPinned {
            // Resume following: snap to current cursor immediately.
            overlay.updatePosition(cursor: NSEvent.mouseLocation)
            probeAndUpdate(at: NSEvent.mouseLocation, force: true)
        } else {
            overlay.refresh()
        }
        log.info("overlay pinned=\(env.overlayPinned)")
    }

    private func probeAndUpdate(at p: NSPoint, force: Bool) {
        let now = CACurrentMediaTime()
        if !force, now - lastProbeAt < probeInterval { return }
        lastProbeAt = now
        let info = probe.element(atCocoa: p) ?? OverlayInfo()
        env.currentElement = info
        dim.setHighlight(info.frame)
    }

    private func handleClick(at cgPoint: CGPoint) {
        guard env.overlayVisible else { return }
        let info = env.currentElement
        guard info.hasContent else {
            log.warn("click ignored — no current element")
            return
        }
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let asset = await self.capturer.capture(info: info) {
                self.session.add(asset)
                self.log.info("captured #\(self.session.assets.count) \(asset.typeLabel) — \(asset.summary)")
            } else {
                self.log.warn("capture failed — no text and no frame")
            }
        }
    }
}
