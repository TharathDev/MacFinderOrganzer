import SwiftUI

class SidebarViewModel: ObservableObject {
    @Published var bookmarkedDirectories: [URL] = []
    @Published var selectedDirectory: URL?
    
    func addBookmark(_ url: URL) {
        if !bookmarkedDirectories.contains(url) {
            bookmarkedDirectories.append(url)
        }
    }
    
    func removeBookmark(_ url: URL) {
        bookmarkedDirectories.removeAll { $0 == url }
    }
}