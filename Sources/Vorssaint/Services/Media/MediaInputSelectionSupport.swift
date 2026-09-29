// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation
import UniformTypeIdentifiers

enum MediaInputSelectionSupport {
    static func validatedURLs(_ urls: [URL], for tool: MediaTool,
                              contentType: (URL) -> UTType? = {
                                  try? $0.resourceValues(forKeys: [.contentTypeKey]).contentType
                              }) -> [URL]? {
        guard !urls.isEmpty,
              MediaSupport.allowsMultipleInputs(for: tool) || urls.count == 1,
              urls.allSatisfy({ $0.isFileURL && MediaSupport.inputMatchesTool(
                  contentType: contentType($0), inputTypes: MediaSupport.inputTypes(for: tool)) })
        else { return nil }
        return urls
    }
}
