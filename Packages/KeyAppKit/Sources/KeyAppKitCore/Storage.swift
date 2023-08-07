import Foundation

public protocol Storage {
    func save(for key: String, data: Data) async throws
    func load(for key: String) async throws -> Data?
}

public class ApplicationFileStorage: Storage {
    public init() {}

    public func save(for key: String, data: Data) async throws {
        guard let filePath = append(toPath: documentDirectory(), withPathComponent: key) else {
            return
        }

        try data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
    }

    public func load(for key: String) async throws -> Data? {
        guard let filePath = append(toPath: documentDirectory(), withPathComponent: key) else {
            return nil
        }

        do {
            return try Data(contentsOf: URL(fileURLWithPath: filePath))
        } catch {
            return nil
        }
    }

    private func documentDirectory() -> String {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true
        )
        return documentDirectory[0]
    }

    private func append(
        toPath path: String,
        withPathComponent pathComponent: String
    ) -> String? {
        if var pathURL = URL(string: path) {
            pathURL.appendPathComponent(pathComponent)

            return pathURL.absoluteString
        }

        return nil
    }
}
