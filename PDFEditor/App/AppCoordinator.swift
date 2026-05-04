import SwiftUI

enum AppSheet: Identifiable {
    case documentPicker
    case merge
    case split(URL)
    case export(URL)
    case saveToFiles(URL)

    var id: String {
        switch self {
        case .documentPicker:         return "documentPicker"
        case .merge:                  return "merge"
        case .split(let url):         return "split-\(url.lastPathComponent)"
        case .export(let url):        return "export-\(url.lastPathComponent)"
        case .saveToFiles(let url):   return "saveToFiles-\(url.lastPathComponent)"
        }
    }
}

final class AppCoordinator: ObservableObject {
    @Published var navigationPath = NavigationPath()
    @Published var activeSheet: AppSheet?

    func openDocumentPicker()       { activeSheet = .documentPicker }
    func openMerge()                { activeSheet = .merge }
    func openSplit(url: URL)        { activeSheet = .split(url) }
    func openExport(url: URL)       { activeSheet = .export(url) }
    func openSaveToFiles(url: URL)  { activeSheet = .saveToFiles(url) }
    func dismiss()                  { activeSheet = nil }
}
