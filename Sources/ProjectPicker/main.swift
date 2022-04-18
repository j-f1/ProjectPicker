import Foundation
import CoreText

let start = Date()

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
            return values.isDirectory == true && values.isPackage != true && !searchURLPaths.contains(url.path) && !url.lastPathComponent.starts(with: ".")  && !url.lastPathComponent.contains("venv") && url.lastPathComponent != "SharedXcodeSettings"
        }
        .map { url in
            return try ProjectWithDate(
                url: url,
                date: try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
            )
        }
}.sorted(using: SortDescriptor(\ProjectWithDate.date, order: .reverse))

let items = projects.map(\.project.alfredItem)

let end = Date()

if ProcessInfo.processInfo.arguments.contains("--info") {
    print("ProjectPicker: Loaded \(projects.count) projects in \((start.distance(to: end) * 1000).formatted(.number.precision(.significantDigits(3))))ms.")

    let byType = projects.reduce(into: [:]) { partialResult, project in
        partialResult[project.project.kind.description, default: Set()].insert(project)
    }
    let maxWidth = (byType.map(\.key.count).max() ?? 0) + 1
    for (kind, projects) in byType.sorted(by: { $0.value.count > $1.value.count }) {
        print("\((kind + ":").padding(toLength: maxWidth, withPad: " ", startingAt: 0)) \(projects.count)")
    }

    if ProcessInfo.processInfo.arguments.contains("--list-unknown") {
        print()
        print("--- Unknown Projects (\(byType["Unknown"]!.count)): ---")
        print(byType["Unknown"]!.map(\.project.friendlyPath).sorted().joined(separator: "\n"))
    }
} else {
    try Alfred.Result(items: items).output(debug: false)
}
