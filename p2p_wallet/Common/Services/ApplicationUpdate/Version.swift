import Foundation

struct Version: Decodable {
    // MARK: - Enumerations

    enum VersionError: Error {
        case invalidFormat
    }

    // MARK: - Public properties

    let major: Int
    let minor: Int
    let patch: Int

    // MARK: - Init

    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.singleValueContainer()
            let version = try container.decode(String.self)
            try self.init(from: version)
        } catch {
            throw VersionError.invalidFormat
        }
    }

    init(from version: String) throws {
        let versionComponents = version.components(separatedBy: ".").map { Int($0) }
        guard versionComponents.count == 3 else {
            throw VersionError.invalidFormat
        }

        guard let major = versionComponents[0], let minor = versionComponents[1],
              let patch = versionComponents[2]
        else {
            throw VersionError.invalidFormat
        }

        self.major = major
        self.minor = minor
        self.patch = patch
    }

    var string: String {
        "\(major).\(minor).\(patch)"
    }
}
