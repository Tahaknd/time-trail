import AppKit
import GRDB

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    private var trackingEngine: TrackingEngine?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let db = DatabaseManager.shared.dbQueue
        statusItemController = StatusItemController(db: db)
        setupTrackingEngine(db: db)
    }

    func applicationWillTerminate(_ notification: Notification) {
        trackingEngine?.stop()
    }

    // MARK: - Private

    private func setupTrackingEngine(db: DatabaseQueue) {
        let repository = ActivitySegmentRepository(db: db)
        let engine = TrackingEngine(repository: repository)
        engine.start()
        trackingEngine = engine
    }
}
