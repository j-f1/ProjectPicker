import Foundation
import CoreText

defer { try? Config.shared.save() }

@objcMembers class ProjectWithDate: NSObject {
    let project: Project
    let date: Date
    init(url: URL, date: Date?) throws  {
        self.project = try Project(url)
        self.date = date ?? .distantPast
    }
}

let searchURLs = Config.shared.searchPaths.map { URL(fileURLWithPath: $0, relativeTo: FileManager.default.homeDirectoryForCurrentUser) }
let searchURLPaths = searchURLs.map(\.path)

let projects = try searchURLs.flatMap { (url) -> [ProjectWithDate] in
    let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey, .contentModificationDateKey], options: [])
    return try urls
        .filter { url in
            let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
            return values.isDirectory == true && values.isPackage != true && !searchURLPaths.contains(url.path)
        }
        .map { url in
            return try ProjectWithDate(
                url: url,
                date: try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
            )
        }
}.sorted(using: SortDescriptor(\ProjectWithDate.date, order: .reverse))

try Alfred.Result(items: projects.map(\.project.alfredItem)).output(debug: false)
