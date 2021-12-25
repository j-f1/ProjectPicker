//
//  Config.swift
//  
//
//  Created by Jed Fox on 2021-12-25.
//

import Foundation

struct Config: Codable {
    var searchPaths: [String]

    static let url = URL(
        fileURLWithPath: "./.config/project-picker.json",
        relativeTo: FileManager.default.homeDirectoryForCurrentUser
    )

    func save() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        try encoder.encode(self).write(to: Self.url)
    }

    static let shared = (try? JSONDecoder().decode(Self.self, from: Data(contentsOf: url))) ?? Self(searchPaths: [])
}
