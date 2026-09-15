import Foundation

enum EnvironmentConfigurationTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("build/config-fixture-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        do {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            try Data().write(to: root.appendingPathComponent(".zshrc"))
            try FileManager.default.createDirectory(at: root.appendingPathComponent(".zprofile"), withIntermediateDirectories: true)
            try Data().write(to: root.appendingPathComponent(".python-version"))
            let user = EnvironmentConfiguration.discover(home: root.path, environment: [:], systemRoot: root.appendingPathComponent("absent").path)
            expect(user.map(\.name) == [".zshrc"], "configuration discovery excludes missing files and directories")
            expect(user.first?.path == root.appendingPathComponent(".zshrc").path, "configuration retains its complete location")
            let project = EnvironmentConfiguration.discoverProject(root.path)
            expect(project.map(\.name) == [".python-version"], "project discovery uses only the selected directory")
        } catch {
            expect(false, "configuration fixture: \(error)")
        }
    }
}
