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
        if kind.shouldOpenIcon {
            return kind.icon.path
        }
        return url.path
    }

    var friendlyPath: String {
        url.path
            .replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "", options: .anchored)
            .removingPercentEncoding!
            .dropFirst()
            .replacingOccurrences(of: "Documents/", with: "", options: .anchored)
    }

    var alfredItem: Alfred.Item {
        let app: String
        if kind.description == kind.appFriendlyName {
            app = kind.appFriendlyName
        } else {
            app = "\(kind.description) (\(kind.appFriendlyName))"
        }
        return .init(
            uid: url.absoluteString,
            title: url.lastPathComponent,
            subtitle: "\(friendlyPath) • \(app)",
            arg: url.path,
            icon: .init(type: .fileIcon, path: kind.icon.path.removingPercentEncoding!),
            valid: true,
            match: nil,
            autocomplete: nil,
            type: .file(skipCheck: true),
            variables: [
                "appName": Config.shared.apps[keyPath: kind.appName],
                "pathToOpen": path.removingPercentEncoding!
            ]
        )
    }

    struct Kind {
        private static let vsCodeName = "Visual Studio Code - Insiders"

        let icon: URL
        let appName: KeyPath<Config.AppNames, String>
        let description: String
        let shouldOpenIcon: Bool

        private static func `default`(icon: URL, description: String) -> Kind {
            Kind(icon: icon, appName: \.default, description: description, shouldOpenIcon: false)
        }
        private static func VSCode(workspace: URL) -> Kind {
            Kind(icon: workspace, appName: \.vscode, description: "VS Code", shouldOpenIcon: true)
        }
        private static func Xcode(icon: URL, description: String) -> Kind {
            Kind(icon: icon, appName: \.xcode, description: description, shouldOpenIcon: false)
        }
        private static func QtCreator(icon: URL) -> Kind {
            Kind(icon: icon, appName: \.qtCreator, description: "Qt Creator", shouldOpenIcon: false)
        }


        var appFriendlyName: String {
            if Config.shared.apps[keyPath: appName] == Config.shared.apps.vscode {
                return "VS Code"
            }
            return Config.shared.apps[keyPath: appName]
        }

        static func infer(from url: URL) throws -> Kind {
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [], options: [])

            let findByExtension = { (ext: String) in contents.first { $0.lastPathComponent.hasSuffix(ext) } }
            let findFile = { (name: String) in contents.first { $0.lastPathComponent == name } }

            // MARK: IDE detection
            if let workspace = findByExtension(".code-workspace") {
                return .VSCode(workspace: workspace)
            }
            if let package = findByExtension("Package.swift") {
                return .Xcode(icon: package, description: "Swift")
            }
            if let workspace = findByExtension(".xcworkspace") {
                return .Xcode(icon: workspace, description: "Xcode (workspace)")
            }
            if let project = findByExtension(".xcodeproj") {
                return .Xcode(icon: project, description: "Xcode")
            }
            if let project = findByExtension(".pro") {
                return .QtCreator(icon: project)
            }

            // MARK: Icon inference for default editor
            if let racket = findByExtension(".rkt") {
                return .default(icon: racket, description: "Racket")
            }

            if let package = findFile("package.json") {
                return .default(icon: package, description: "Node.js")
            }
            if let requirements = findFile("requirements.txt") {
                return .default(icon: requirements, description: "Python")
            }
            if let dune = findFile("dune-project") {
                return .default(icon: dune, description: "OCaml")
            }
            if let make = findFile("Makefile") {
                return .default(icon: make, description: "C")
            }
            if let make = findFile("Makefile.am") {
                return .default(icon: make, description: "C")
            }
            if let cMake = findFile("CMakeLists.txt") {
                return .default(icon: cMake, description: "C")
            }
            if let porn = findFile("pom.xml") {
                return .default(icon: porn, description: "Java")
            }
            if let gems = findFile("Gemfile") {
                return .default(icon: gems, description: "Ruby")
            }
            if let config = findFile("_config.yml") {
                return .default(icon: config, description: "Jekyll")
            }
            if let goMod = findFile("go.mod") {
                return .default(icon: goMod, description: "Go")
            }
            if findFile("__pycache__") != nil {
                return .default(icon: url, description: "Python")
            }

            return .default(icon: url, description: "Unknown")
        }
    }
}
