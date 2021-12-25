//
//  Project.swift
//  
//
//  Created by Jed Fox on 2021-12-25.
//

import Foundation

struct Project {
    let url: URL
    let kind: Kind

    init(_ url: URL) throws {
        self.url = url
        self.kind = try .infer(from: url)
    }

    var path: String {
        if case .VSCode(let workspace) = kind {
            return workspace.path
        }
        return url.path
    }

    var alfredItem: Alfred.Item {
        .init(
            uid: url.absoluteString,
            title: url.lastPathComponent,
            subtitle: url.path
                .replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "")
                .removingPercentEncoding,
            arg: url.path,
            icon: .init(type: .fileIcon, path: kind.iconURL.path.removingPercentEncoding!),
            valid: true,
            match: nil,
            autocomplete: nil,
            type: .file(skipCheck: true),
            variables: [
                "appName": kind.appName,
                "pathToOpen": path.removingPercentEncoding!
            ]
        )
    }

    enum Kind {
        case `default`(icon: URL)
        case VSCode(workspace: URL)
        case Xcode(icon: URL)
        case QTCreator(icon: URL)

        var appName: String {
            switch self {
            case .default, .VSCode: return "Visual Studio Code - Insiders"
            case .Xcode: return "Xcode"
            case .QTCreator: return "Qt Creator"
            }
        }

        var iconURL: URL {
            switch self {
            case .default(let icon):
                return icon
            case .VSCode(let workspace):
                return workspace
            case .Xcode(let icon):
                return icon
            case .QTCreator(let icon):
                return icon
            }
        }

        static func infer(from url: URL) throws -> Kind {
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [], options: [])

            let findByExtension = { (ext: String) in contents.first { $0.lastPathComponent.hasSuffix(ext) } }
            let findFile = { (name: String) in contents.first { $0.lastPathComponent == name } }

            if let workspace = findByExtension(".code-workspace") {
                return .VSCode(workspace: workspace)
            }
            if let workspace = findByExtension(".xcworkspace") {
                return .Xcode(icon: workspace)
            }
            if let project = findByExtension(".xcodeproj") {
                return .Xcode(icon: project)
            }
            if let project = findByExtension(".pro") {
                return .QTCreator(icon: project)
            }

            if let package = findFile("package.json") {
                return .default(icon: package)
            }

            return .default(icon: url)
        }
    }
}
