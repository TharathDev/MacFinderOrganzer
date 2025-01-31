import SwiftUI

class OrganizerViewModel: ObservableObject {
    @Published var isOrganizing: Bool = false
    @Published var organizationResults: [String: [URL]] = [:]
    @Published var progressLogs: [String] = []
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    func organizeFolder(at url: URL, fileOperationsVM: FileOperationsViewModel) {
        isOrganizing = true
        progressLogs.removeAll()
        organizationResults.removeAll()
        
        FileOrganizer.organize(
            path: url.path,
            onProgress: { [weak self] log in
                DispatchQueue.main.async {
                    self?.progressLogs.append(log)
                }
            },
            onCategoryUpdate: { [weak self] category, filePaths in
                DispatchQueue.main.async {
                    let urls = filePaths.map { URL(fileURLWithPath: $0) }
                    self?.organizationResults[category] = urls
                }
            },
            completion: { [weak self] result in
                DispatchQueue.main.async {
                    self?.isOrganizing = false
                    self?.alertMessage = result
                    self?.showAlert = true
                    fileOperationsVM.updateDirectoryContents(for: url)
                }
            }
        )
    }
}