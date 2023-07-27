import Foundation
import CoreText

let start = Date()

defer { try? Config.shared.save() }

extension Sequence {
    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>, reversed: Bool = false) -> [Element] {
        sorted(by: reversed
               ? { $0[keyPath: keyPath] > $1[keyPath: keyPath] }
               : { $0[keyPath: keyPath] < $1[keyPath: keyPath] })
    }
}

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
            return values.isDirectory == true && values.isPackage != true && !searchURLPaths.contains(url.path) && !url.lastPathComponent.starts(with: ".")  && !url.lastPathComponent.contains("venv") && !(url.lastPathComponent.starts(with: "build-") && url.lastPathComponent.contains("Qt") && url.lastPathComponent.contains("_for_macOS-")) && url.lastPathComponent != "SharedXcodeSettings"
        }
        .map { url in
            return try ProjectWithDate(
                url: url,
                date: try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
            )
        }
}.sorted(by: \.date)

let items = projects.map(\.project.alfredItem)

let end = Date()

if ProcessInfo.processInfo.arguments.contains("--info") {
    print("ProjectPicker: Loaded \(projects.count) projects in \((start.distance(to: end) * 1000).formatted(.number.precision(.significantDigits(3))))ms.")

    let byType = projects.reduce(into: [:]) { partialResult, project in
        partialResult[project.project.kind.description, default: Set()].insert(project)
    }
    let maxWidth = (byType.map(\.key.count).max() ?? 0) + 1

    var firstTable = [
        "\(String(repeating: " ", count: maxWidth - "Project Kind".count))Project Kind  Count ↓",
        "",
//        "\(String(repeating: " ", count: maxWidth))  -----",
    ]
    for (kind, projects) in byType.sorted(by: \.value.count, reversed: true) {
        if kind == "Unknown" { continue }
        firstTable.append("\(String(repeating: " ", count: maxWidth - kind.count))\(kind)  \(projects.count)")
    }

    var secondTable = [
        "\(String(repeating: " ", count: maxWidth - "↓ Project Kind".count))↓ Project Kind  Count",
        "",
//        "\(String(repeating: " ", count: maxWidth - "Project Kind".count))------------",
    ]
    for (kind, projects) in byType.sorted(by: \.key) {
        if kind == "Unknown" { continue }
        secondTable.append("\(String(repeating: " ", count: maxWidth - kind.count))\(kind)  \(projects.count)")
    }

    print()
    for (lhs, rhs) in zip(secondTable, firstTable) {
        print("\(lhs)\(String(repeating: " ", count: firstTable.map(\.count).max()! - lhs.count))  |  \(rhs)")
    }

    if ProcessInfo.processInfo.arguments.contains("--list-unknown") {
        print("\n")
        print("--- Unknown Projects (\(byType["Unknown"]!.count)): ---")
        print(byType["Unknown"]!.map(\.project.friendlyPath).sorted().joined(separator: "\n"))
    }
} else {
    try Alfred.Result(items: items).output(debug: false)
}
