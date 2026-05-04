import SwiftUI

@main
struct PDFEditorApp: App {
    @State private var coordinator = AppCoordinator()
    private let environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(coordinator)
                .environmentObject(environment)
        }
    }
}
