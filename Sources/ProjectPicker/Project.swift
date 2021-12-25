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
            icon: .init(type: .fileIcon, path: path),
            valid: true,
            match: nil,
            autocomplete: url.path.removingPercentEncoding,
            type: .file(skipCheck: true),
            variables: [
                "appName": kind.appName,
                "pathToOpen": path
            ]
        )
    }

    enum Kind {
        case `default`
        case VSCode(workspace: URL)
        case Xcode
        case QTCreator

        var appName: String {
            switch self {
            case .default, .VSCode: return "Visual Studio Code - Insiders"
            case .Xcode: return "Xcode"
            case .QTCreator: return "Qt Creator"
            }
        }

        static func infer(from url: URL) throws -> Kind {
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [], options: [])

            if let workspace = contents.first(where: { $0.lastPathComponent.hasSuffix(".code-workspace") }) {
                return .VSCode(workspace: workspace)
            }
            if contents.contains(where: { $0.lastPathComponent.hasSuffix(".xcodeproj") }) {
                return .Xcode
            }
            if contents.contains(where: { $0.lastPathComponent.hasSuffix(".pro") }) {
                return .QTCreator
            }

            return .default
        }
    }
}
