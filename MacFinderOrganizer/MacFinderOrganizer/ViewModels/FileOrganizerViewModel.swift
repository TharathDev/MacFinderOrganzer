import SwiftUI

class FileOrganizerViewModel: ObservableObject {
    @Published var sidebarVM: SidebarViewModel
    @Published var fileOperationsVM: FileOperationsViewModel
    @Published var organizerVM: OrganizerViewModel
    
    init() {
        self.sidebarVM = SidebarViewModel()
        self.fileOperationsVM = FileOperationsViewModel()
        self.organizerVM = OrganizerViewModel()
    }
    
    func organizeSelectedFolder() {
        guard let url = sidebarVM.selectedDirectory else { return }
        organizerVM.organizeFolder(at: url, fileOperationsVM: fileOperationsVM)
    }
}