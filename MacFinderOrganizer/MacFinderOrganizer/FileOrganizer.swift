import Foundation

class FileOrganizer {
    static let categories: [String: Set<String>] = [
        "Images": ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp"],
        "Documents": ["doc", "docx", "txt", "rtf", "pages", "odt"],
        "PDFs": ["pdf"],
        "Audio": ["mp3", "wav", "m4a", "aac", "flac"],
        "Video": ["mp4", "mov", "avi", "mkv", "wmv"],
        "Archives": ["zip", "rar", "7z", "tar", "gz"],
        "Applications": ["dmg", "exe", "app", "msi", "pkg", "deb", "rpm"],
        "Others": []
    ]
    
    static func organize(path: String, 
                        onProgress: @escaping (String) -> Void,
                        onCategoryUpdate: @escaping (String, [String]) -> Void,
                        completion: @escaping (String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            var message = "Organization completed successfully!"
            var categoryResults: [String: [String]] = [:]
            var requiredCategories: Set<String> = []
            
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: path)
                onProgress("Found \(contents.count) items to organize")
                
                // First pass: identify which categories are needed
                for file in contents {
                    let filePath = (path as NSString).appendingPathComponent(file)
                    var isDirectory: ObjCBool = false
                    
                    guard fileManager.fileExists(atPath: filePath, isDirectory: &isDirectory),
                          !isDirectory.boolValue else { continue }
                    
                    let fileExtension = (file as NSString).pathExtension.lowercased()
                    var targetCategory = "Others"
                    
                    for (category, extensions) in categories {
                        if extensions.contains(fileExtension) {
                            targetCategory = category
                            break
                        }
                    }
                    requiredCategories.insert(targetCategory)
                }
                
                // Initialize results for required categories
                for category in requiredCategories {
                    categoryResults[category] = []
                }
                
                // Create only needed category folders
                for category in requiredCategories {
                    let categoryPath = (path as NSString).appendingPathComponent(category)
                    if !fileManager.fileExists(atPath: categoryPath) {
                        try fileManager.createDirectory(atPath: categoryPath, withIntermediateDirectories: true)
                        onProgress("Created category folder: \(category)")
                    }
                }
                
                // Organize files
                for file in contents {
                    let filePath = (path as NSString).appendingPathComponent(file)
                    var isDirectory: ObjCBool = false
                    
                    if fileManager.fileExists(atPath: filePath, isDirectory: &isDirectory) && !isDirectory.boolValue {
                        let fileExtension = (file as NSString).pathExtension.lowercased()
                        var targetCategory = "Others"
                        
                        for (category, extensions) in categories {
                            if extensions.contains(fileExtension) {
                                targetCategory = category
                                break
                            }
                        }
                        
                        let categoryPath = (path as NSString).appendingPathComponent(targetCategory)
                        let destinationPath = (categoryPath as NSString).appendingPathComponent(file)
                        
                        if !fileManager.fileExists(atPath: destinationPath) {
                            try fileManager.moveItem(atPath: filePath, toPath: destinationPath)
                            categoryResults[targetCategory]?.append(file)
                            onProgress("Moved '\(file)' to \(targetCategory)")
                            onCategoryUpdate(targetCategory, categoryResults[targetCategory] ?? [])
                        }
                    }
                }
            } catch {
                message = "Error organizing files: \(error.localizedDescription)"
                onProgress("Error: \(error.localizedDescription)")
            }
            
            completion(message)
        }
    }
}
