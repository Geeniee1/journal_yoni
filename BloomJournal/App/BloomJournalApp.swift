import SwiftUI
import SwiftData

@main
struct BloomJournalApp: App {
    private let modelContainer = AppContainer.shared.sharedModelContainer
    @StateObject private var lockController = AppLockController()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(lockController)
                .modelContainer(modelContainer)
                .task {
                    lockController.configure()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    lockController.handle(scenePhase: newPhase)
                }
        }
    }
}
