import SwiftUI

enum AppSheet: Identifiable {
    case documentPicker
    case merge
    case split
    case export(URL)

    var id: String {
        switch self {
        case .documentPicker: return "documentPicker"
        case .merge: return "merge"
        case .split: return "split"
        case .export: return "export"
        }
    }
}

final class AppCoordinator: ObservableObject {
    @Published var navigationPath = NavigationPath()
    @Published var activeSheet: AppSheet?

    func openDocumentPicker() {
        activeSheet = .documentPicker
    }

    func openMerge() {
        activeSheet = .merge
    }

    func openSplit() {
        activeSheet = .split
    }

    func openExport(url: URL) {
        activeSheet = .export(url)
    }

    func dismiss() {
        activeSheet = nil
    }
}
