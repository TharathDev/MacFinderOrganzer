import SwiftUI

// Add this import
import Foundation

class FileOperationsViewModel: ObservableObject {
    @Published var directoryContents: [FileItem] = []
    
    func updateDirectoryContents(for url: URL) {
        do {
            let resourceKeys: [URLResourceKey] = [
                .isDirectoryKey,
                .fileSizeKey,
                .contentModificationDateKey
            ]
            
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: resourceKeys,
                options: [.skipsHiddenFiles]
            )
            
            directoryContents = try contents.map { fileURL in
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                return FileItem(
                    url: fileURL,
                    name: fileURL.lastPathComponent,
                    isDirectory: resourceValues.isDirectory ?? false,
                    size: Int64(resourceValues.fileSize ?? 0),
                    modificationDate: resourceValues.contentModificationDate ?? Date()
                )
            }.sorted(by: { $0.name < $1.name })
        } catch {
            directoryContents = []
            print("Error reading directory: \(error)")
        }
    }
}