//
//  Project.swift
//  
//
//  Created by Jed Fox on 2021-12-25.
//

import Foundation

struct Project {
    let url: URL
    let name: String
    let kind: Kind?

    init(_ url: URL) throws {
        self.url = url
        self.name = url.lastPathComponent

        self.kind = try .infer(from: url)
    }

    enum Kind {
        case VSCode(workspace: URL)
        case Xcode
        case QTCreator

        static func infer(from url: URL) throws -> Kind? {
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

            return nil
        }
    }
}
