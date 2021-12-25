import Foundation
import CoreText

defer { try? Config.shared.save() }

let projects = try Config.shared.searchPaths.flatMap { (path) -> [Project] in
    let url = URL(fileURLWithPath: path, relativeTo: FileManager.default.homeDirectoryForCurrentUser)
    let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [])
    return try urls
        .filter { try $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true }
        .map(Project.init)
}

print(projects)
