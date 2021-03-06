//
//  Writer.swift
//  jargon
//
//  Created by David Miotti on 02/03/2017.
//
//

import Foundation

/// Write translations files in the current directory
///
/// - Parameters:
///   - translations: Translations to write
///   - project: Project folder name
/// - Throws: Error writing the translation
func writeiOS(_ translations: [Translation], for project: String, baseLang: String) throws -> [URL] {
    var fileUrls = try translations.map { try write(translation: $0, for: project) }
    var baseTranslation: Translation?
    if baseLang == "default" {
        baseTranslation = translations.first
    } else if let trans = translations.filter({ $0.lang == baseLang }).first {
        baseTranslation = trans
    }
    if let trans = baseTranslation {
        let baseUrl = try write(translation: trans, for: project, isBase: true)
        fileUrls.append(baseUrl)
    }
    return fileUrls
}

/// Write a translation on disk based on the project name
///
/// - Parameters:
///   - translation: The translation to be written
///   - project: The project name that describe the directory where Localizable.string should reside
/// - Throws: Most of the time a filesystem permission problem or insufficient disk space
private func write(translation: Translation, for project: String, isBase: Bool = false) throws -> URL {
    let fileUrl = try buildFilePath(forProject: project, lang: translation.lang, isBase: isBase)
    let contents = fileContents(for: translation)
    let data = contents.data(using: .utf8)
    try data?.write(to: fileUrl)
    return fileUrl
}

/// Transform a Translation object to a string content
///
/// - Parameter translation: The translation to be transformed
/// - Returns: The string containing the translation text
private func fileContents(for translation: Translation) -> String {
    let lines = translation.translations.map(buildLine)
    return lines.joined(separator: "\n")
}

/// Construct a line from a translation entry that is conform with iOS
///
/// - Parameters:
///   - key: The current key
///   - value: The value for the provided key
/// - Returns: A line that is conform with iOS projects
private func buildLine(for key: String, value: String) -> String {
    let normalized = normalize(value)
    return "\"\(key)\" = \"\(normalized)\";"
}

/// Transform the string into correct parseable iOS format
///
/// - Parameter string: The parsed to be formatted
/// - Returns: The formatted string
private func normalize(_ string: String) -> String {
    let replaceTable = [
        "%s": "%@",
        "%([0-9]\\$)+s": "%$1@",
        "%newline%": "\\\\n",
        "\"": "\\\\\"",
        "\\n": "\\\\n"
    ]
    return replaceTable.reduce(string) {
        $0.replacingOccurrences(
            of: $1.key,
            with: $1.value,
            options: [.regularExpression, .caseInsensitive]
        )
    }
}

/// Construct the file url of translation
///
/// - Parameters:
///   - name: The name
///   - lang: The lang description
/// - Returns: The url of the Localization.string based on the project name
/// - Throws: An error if directories failed to creates
private func buildFilePath(forProject name: String, lang: String, isBase: Bool = false) throws -> URL {
    let fileManager = FileManager.default
    let currDir = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    let projDir = currDir.appendingPathComponent(name)
    let filename = isBase ? "Base" : lang
    let transDir = projDir.appendingPathComponent("\(filename).lproj")
    try fileManager.createDirectory(at: transDir, withIntermediateDirectories: true, attributes: nil)
    return transDir.appendingPathComponent("Localizable.strings")
}
