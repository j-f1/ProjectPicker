//
//  Config.swift
//  
//
//  Created by Jed Fox on 2021-12-25.
//

import Foundation

struct Config: Codable {
    var searchPaths: [String]
    var apps: AppNames

    struct AppNames: Codable {
        let `default`: String
        var xcode: String = "Xcode"
        var vscode: String = "Visual Studio Code"
        var qtCreator: String = "Qt Creator"
        var arduino: String = "Arduino IDE"
    }

    static let url = URL(
        fileURLWithPath: "./.config/project-picker.json",
        relativeTo: FileManager.default.homeDirectoryForCurrentUser
    )

    func save() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        try encoder.encode(self).write(to: Self.url)
    }

    static let shared: Self = {
        do {
            return try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        } catch {
            print("Error parsing projects JSON!")
            switch error as? DecodingError {
            case .dataCorrupted(let ctx), .typeMismatch(_, let ctx):
                debugContext(ctx)
            case .valueNotFound(let type, let ctx):
                print("Value of type \(type) not found")
                debugContext(ctx)
            case .keyNotFound(let key, let ctx):
                print("Key \(key.stringValue) not found")
                debugContext(ctx)
            case nil:
                break
            case .some:
                print(error.localizedDescription)
            }
            fatalError()
        }
    }()
}

private func debugContext(_ ctx: DecodingError.Context) {
    print("Key path: <root>\(ctx.codingPath.map { "." + $0.stringValue }.joined())")
    print(ctx.debugDescription)
    if let underlying = ctx.underlyingError as NSError?,
       let debugDescription = underlying.userInfo["NSDebugDescription"] {
        print(debugDescription)
    }
}

extension Config.AppNames {
    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<Config.AppNames.CodingKeys> = try decoder.container(keyedBy: Config.AppNames.CodingKeys.self)
        let auto = Config.AppNames(default: "")
        self.default = try container.decode(String.self, forKey: .default)
        self.xcode = try container.decodeIfPresent(String.self, forKey: .xcode) ?? auto.xcode
        self.vscode = try container.decodeIfPresent(String.self, forKey: .vscode) ?? auto.vscode
        self.qtCreator = try container.decodeIfPresent(String.self, forKey: .qtCreator) ?? auto.qtCreator
        self.arduino = try container.decodeIfPresent(String.self, forKey: .arduino) ?? auto.arduino
    }
}
