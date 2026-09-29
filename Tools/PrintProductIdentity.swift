// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

@main
enum PrintProductIdentity {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard arguments.count == 1 || arguments.count == 3,
              arguments[0] == "0" || arguments[0] == "1" else {
            throw NSError(domain: "ProductIdentityTool", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Usage: identity 0|1 [--render-bundle path]"])
        }
        let development = arguments[0] == "1"
        let values = [
            "APP_NAME": ProductIdentity.appName(development: development),
            "EXECUTABLE": ProductIdentity.executableName(development: development),
            "APP_BUNDLE_ID": ProductIdentity.bundleID(development: development),
            "REPOSITORY_URL": ProductIdentity.repositoryURL.absoluteString,
        ]
        if arguments.count == 3 {
            guard arguments[1] == "--render-bundle" else {
                throw NSError(domain: "ProductIdentityTool", code: 2)
            }
            let root = URL(fileURLWithPath: arguments[2], isDirectory: true)
            guard let files = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else {
                throw NSError(domain: "ProductIdentityTool", code: 3)
            }
            for case let file as URL in files where file.lastPathComponent == "Info.plist" || file.lastPathComponent == "InfoPlist.strings" {
                var text = try String(contentsOf: file, encoding: .utf8)
                for (key, value) in values { text = text.replacingOccurrences(of: "__" + key + "__", with: value) }
                try text.write(to: file, atomically: true, encoding: .utf8)
            }
        } else {
            let data = try PropertyListSerialization.data(fromPropertyList: values, format: .xml, options: 0)
            FileHandle.standardOutput.write(data)
        }
    }
}
