import ApplicationServices
import Foundation

final class AccessibilityPermissionChecker: ObservableObject {
    @Published private(set) var isGranted: Bool

    private var timer: Timer?

    init() {
        isGranted = AXIsProcessTrusted()
        if !isGranted {
            startPolling()
        }
    }

    deinit {
        timer?.invalidate()
    }

    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if AXIsProcessTrusted() {
                DispatchQueue.main.async {
                    self.isGranted = true
                }
                self.timer?.invalidate()
                self.timer = nil
            }
        }
    }
}
