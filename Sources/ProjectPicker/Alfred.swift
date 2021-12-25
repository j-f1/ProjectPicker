//
//  File.swift
//  
//
//  Created by Jed Fox on 2021-12-25.
//

import Foundation

enum Alfred {
    struct Result: Codable {
        let items: [Item]

        func output(debug: Bool) throws {
            let encoder = JSONEncoder()
            encoder.outputFormatting = debug ? [.prettyPrinted, .withoutEscapingSlashes] : .withoutEscapingSlashes
            try FileHandle.standardOutput.write(contentsOf: encoder.encode(self))
        }
    }

    // intentionally incomplete.
    struct Item: Codable {
        /// This is a unique identifier for the item which allows help Alfred to learn about this item for subsequent sorting and ordering of the user's actioned results.
        ///
        /// It is important that you use the same UID throughout subsequent executions of your script to take advantage of Alfred's knowledge and sorting. If you would like Alfred to always show the results in the order you return them from your script, exclude the UID field.
        let uid: String

        /// The title displayed in the result row. There are no options for this element and it is essential that this element is populated.
        let title: String

        /// The subtitle displayed in the result row. This element is optional.
        let subtitle: String?

        /// The argument which is passed through the workflow to the connected output action.
        let arg: [String]

        /// The icon displayed in the result row. Workflows are run from their workflow folder, so you can reference icons stored in your workflow relatively.
        let icon: Icon
        struct Icon: Codable {
            /// By omitting the `type`, Alfred will load the file path itself, for example a png.
            let type: IconType?
            let path: String

            enum IconType: String, Codable {
                case fileIcon = "fileicon"
                case uti = "filetype"
            }
        }

        /// If this item is valid or not. If an item is valid then Alfred will action this item when the user presses return. If the item is not valid, Alfred will do nothing. This allows you to intelligently prevent Alfred from actioning a result based on the current {query} passed into your script.
        ///
        /// If you exclude the valid attribute, Alfred assumes that your item is valid.
        let valid: Bool?

        /// From Alfred 3.5, the `match` field enables you to define what Alfred matches against when the workflow is set to "Alfred Filters Results". If match is present, it fully replaces matching on the title property.
        ///
        /// Note that the `match` field is always treated as case insensitive, and intelligently treated as diacritic insensitive. If the search query contains a diacritic, the match becomes diacritic sensitive.`
        let match: String?

        /// An optional but recommended string you can provide which is populated into Alfred's search field if the user auto-complete's the selected result (⇥ by default).
        /// If the item is set as `"valid": false`, the auto-complete text is populated into Alfred's search field when the user actions the result.
        let autocomplete: String?

        /// By specifying `"type": "file"`, this makes Alfred treat your result as a file on your system. This allows the user to perform actions on the file like they can with Alfred's standard file filters.
        /// When returning files, Alfred will check if the file exists before presenting that result to the user. This has a very small performance implication but makes the results as predictable as possible. If you would like Alfred to skip this check as you are certain that the files you are returning exist, you can use `"type": "file:skipcheck"`.
        let type: ItemType?
        enum ItemType: Codable {
            case `default`
            case file(skipCheck: Bool = false)

            func encode(to coder: Encoder) throws {
                var container = coder.singleValueContainer()
                switch self {
                case .default:
                    try container.encode("default")
                case .file(let skipCheck):
                    if skipCheck {
                        try container.encode("file:skipcheck")
                    } else {
                        try container.encode("file")
                    }
                }
            }
        }

        let variables: [String: String]
    }
}
