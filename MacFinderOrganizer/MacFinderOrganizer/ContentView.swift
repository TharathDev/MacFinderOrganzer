//
//  ContentView.swift
//  MacFinderOrganizer
//
//  Created by Tharath Tho on 31/1/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedPath: String = ""
    @State private var isOrganizing: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var directoryContents: [String] = []
    @State private var organizationResults: [String: [String]] = [:]
    @State private var progressLogs: [String] = []
    @State private var bookmarkedDirectories: [URL] = []
    @State private var selectedDirectory: URL?
    
    private func iconForItem(_ item: String) -> (icon: String, color: Color) {
        let lowercased = item.lowercased()
        
        // Check if it's a directory
        if (try? FileManager.default.attributesOfItem(atPath: selectedPath + "/" + item)[.type] as? FileAttributeType) == .typeDirectory {
            return ("folder.fill", .blue)
        }
        
        // Images
        if lowercased.hasSuffix((".jpg")) || lowercased.hasSuffix(".png") || lowercased.hasSuffix(".jpeg") {
            return ("photo.fill", .purple)
        }
        // Documents
        if lowercased.hasSuffix(".pdf") {
            return ("doc.fill", .red)
        }
        if lowercased.hasSuffix(".doc") || lowercased.hasSuffix(".docx") {
            return ("doc.fill", .blue)
        }
        // Audio
        if lowercased.hasSuffix(".mp3") || lowercased.hasSuffix(".wav") {
            return ("music.note", .pink)
        }
        // Video
        if lowercased.hasSuffix(".mp4") || lowercased.hasSuffix(".mov") {
            return ("film.fill", .orange)
        }
        // Archives
        if lowercased.hasSuffix(".zip") || lowercased.hasSuffix(".rar") {
            return ("archivebox.fill", .brown)
        }
        
        return ("doc", .gray)
    }

    var body: some View {
        NavigationView {
            // Sidebar
            VStack(spacing: 0) {
                // Fixed Add Folder button
                Button(action: selectFolder) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Add Folder")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(8)
                .buttonStyle(PlainButtonStyle())  // Add this line to remove the default button styling
                
                // Scrollable sidebar list
                List {
                    Section(header: Text("Favorites")) {
                        ForEach(bookmarkedDirectories, id: \.self) { url in
                            NavigationLink(
                                destination: DirectoryContentView(
                                    url: url,
                                    contents: directoryContents,
                                    isOrganizing: $isOrganizing,
                                    organizationResults: $organizationResults,
                                    progressLogs: $progressLogs,
                                    onAppear: {
                                        selectedDirectory = url
                                        updateDirectoryContents(for: url)
                                    }
                                )
                            ) {
                                HStack {
                                    Image(systemName: "folder")
                                    Text(url.lastPathComponent)
                                }
                            }
                        }
                    }
                }
                .listStyle(SidebarListStyle())
            }
            .frame(minWidth: 200)
            
            // Initial content view
            Text("Select a folder from the sidebar")
                .foregroundColor(.gray)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if let _ = selectedDirectory {
                    Button(action: organizeSelectedFolder) {
                        Label("Organize", systemImage: "folder.badge.gearshape")
                    }
                    .disabled(isOrganizing)
                }
            }
        }
        .alert("Organization Result", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}

// Directory Content View
struct DirectoryContentView: View {
    let url: URL
    let contents: [String]  // This is the parameter we should use
    @Binding var isOrganizing: Bool
    @Binding var organizationResults: [String: [String]]
    @Binding var progressLogs: [String]
    let onAppear: () -> Void  // Add this property
    
    private func getFileInfo(_ item: String) -> (name: String, kind: String, date: String) {
        let itemPath = url.appendingPathComponent(item)
        let attributes = try? FileManager.default.attributesOfItem(atPath: itemPath.path)
        
        let modificationDate = attributes?[.modificationDate] as? Date ?? Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        let fileType = (attributes?[.type] as? FileAttributeType) ?? .typeRegular
        let kind = fileType == .typeDirectory ? "Folder" : (item as NSString).pathExtension.uppercased()
        
        return (item, kind, dateFormatter.string(from: modificationDate))
    }
    
    private func truncateFileName(_ fileName: String) -> String {
        let maxLength = 30 // Adjust this value based on your needs
        if fileName.count <= maxLength {
            return fileName
        }
        
        let ext = (fileName as NSString).pathExtension
        let nameWithoutExt = (fileName as NSString).deletingPathExtension
        
        if nameWithoutExt.count <= maxLength - 5 { // -5 for "..." and minimum ext length
            return fileName
        }
        
        let truncatedLength = (maxLength - 3 - ext.count) / 2
        let start = String(nameWithoutExt.prefix(truncatedLength))
        let end = String(nameWithoutExt.suffix(truncatedLength))
        
        return "\(start)...\(end).\(ext)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Column Headers
            HStack {
                Text("")
                    .frame(width: 30)  // Space for icon
                Text("Name")
                    .fontWeight(.medium)
                    .frame(minWidth: 200, alignment: .leading)
                Text("Kind")
                    .fontWeight(.medium)
                    .frame(width: 100, alignment: .leading)
                    .padding(.leading, 40)  // Increased padding
                Text("Date Modified")
                    .fontWeight(.medium)
                    .frame(minWidth: 150, alignment: .leading)
                    .padding(.leading, 40)  // Increased padding
                Spacer()
            }
            .padding(.leading, 16)  // Match list item padding
            .padding(.trailing)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
            .border(Color(NSColor.separatorColor), width: 0.5)
            .background(Color.gray.opacity(0.1))
            
            List {
                Section {  // Removed the header text since we have column headers now
                    ForEach(contents, id: \.self) { item in
                        let fileInfo = getFileInfo(item)
                        let iconInfo = iconForItem(item)
                        
                        HStack {
                            Image(systemName: iconInfo.icon)
                                .foregroundColor(iconInfo.color)
                                .frame(width: 30)
                            
                            Text(truncateFileName(fileInfo.name))
                                .frame(minWidth: 200, alignment: .leading)
                                .lineLimit(1)
                            
                            Text(fileInfo.kind)
                                .foregroundColor(.secondary)
                                .frame(width: 100, alignment: .leading)
                                .padding(.leading, 40)  // Updated to match header padding
                            
                            Text(fileInfo.date)
                                .foregroundColor(.secondary)
                                .frame(minWidth: 150, alignment: .leading)
                                .padding(.leading, 40)  // Updated to match header padding
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                if !organizationResults.isEmpty {
                    Section(header: Text("Organized Files")) {
                        ForEach(Array(organizationResults.keys).sorted(), id: \.self) { category in
                            DisclosureGroup {
                                ForEach(organizationResults[category] ?? [], id: \.self) { file in
                                    HStack {
                                        let iconInfo = iconForItem(file)
                                        Image(systemName: iconInfo.icon)
                                            .foregroundColor(iconInfo.color)
                                        Text(file)
                                            .font(.system(.body, design: .monospaced))
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.blue)
                                    Text(category)
                                }
                            }
                        }
                    }
                }
            }
            
            if !progressLogs.isEmpty {
                VStack(alignment: .leading) {
                    Text("Progress")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(progressLogs, id: \.self) { log in
                                Text(log)
                                    .font(.system(.caption, design: .monospaced))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(height: 100)
                .padding()
                .background(Color.black.opacity(0.05))
            }
        }
        .navigationTitle(url.lastPathComponent)
        .onAppear {
            onAppear()
        }
    }
    
    // Add the iconForItem function to DirectoryContentView
    private func iconForItem(_ item: String) -> (icon: String, color: Color) {
        let lowercased = item.lowercased()
        
        // Check if it's a directory
        if (try? FileManager.default.attributesOfItem(atPath: url.path + "/" + item)[.type] as? FileAttributeType) == .typeDirectory {
            return ("folder.fill", .blue)
        }
        
        // Rest of the icon logic remains the same
        if lowercased.hasSuffix((".jpg")) || lowercased.hasSuffix(".png") || lowercased.hasSuffix(".jpeg") {
            return ("photo.fill", .purple)
        }
        // Documents
        if lowercased.hasSuffix(".pdf") {
            return ("doc.fill", .red)
        }
        if lowercased.hasSuffix(".doc") || lowercased.hasSuffix(".docx") {
            return ("doc.fill", .blue)
        }
        // Audio
        if lowercased.hasSuffix(".mp3") || lowercased.hasSuffix(".wav") {
            return ("music.note", .pink)
        }
        // Video
        if lowercased.hasSuffix(".mp4") || lowercased.hasSuffix(".mov") {
            return ("film.fill", .orange)
        }
        // Archives
        if lowercased.hasSuffix(".zip") || lowercased.hasSuffix(".rar") {
            return ("archivebox.fill", .brown)
        }
        
        return ("doc", .gray)
    }
}

// Helper methods for ContentView
extension ContentView {
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.message = "Select a folder to organize"
        panel.prompt = "Choose"
        
        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            
            do {
                let bookmarkData = try url.bookmarkData(options: .withSecurityScope,
                                                       includingResourceValuesForKeys: nil,
                                                       relativeTo: nil)
                UserDefaults.standard.set(bookmarkData, forKey: "bookmarkedDirectories")
                bookmarkedDirectories.append(url)
                updateDirectoryContents(for: url)
            } catch {
                alertMessage = "Error creating bookmark: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func updateDirectoryContents(for url: URL) {
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: url.path)
            directoryContents = contents.sorted()
        } catch {
            directoryContents = []
        }
    }
    
    private func organizeSelectedFolder() {
        guard let url = selectedDirectory else { return }
        isOrganizing = true
        progressLogs.removeAll()
        organizationResults.removeAll()
        
        FileOrganizer.organize(
            path: url.path,
            onProgress: { log in
                DispatchQueue.main.async {
                    progressLogs.append(log)
                }
            },
            onCategoryUpdate: { category, files in
                DispatchQueue.main.async {
                    organizationResults[category] = files
                }
            },
            completion: { result in
                DispatchQueue.main.async {
                    isOrganizing = false
                    alertMessage = result
                    showAlert = true
                    updateDirectoryContents(for: url)
                }
            }
        )
    }
}