import SwiftUI

@main
struct PDFEditorApp: App {
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinator)
                .environmentObject(environment)
                .task { environment.documentManager.clearTemp() }
        }
    }
}
