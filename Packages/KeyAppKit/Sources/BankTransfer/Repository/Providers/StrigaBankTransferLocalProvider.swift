import Foundation

protocol StrigaBankTransferProvider {
    func getCachedRegistrationData() -> RegistrationData?
    func save(registrationData: RegistrationData) throws
    func clearRegistrationData()
}

final class StrigaBankTransferLocalProvider: StrigaBankTransferProvider {
    private let cacheFile: URL = {
        let arrayPaths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDirectoryPath = arrayPaths[0]
        return cacheDirectoryPath.appendingPathComponent("/striga-registration.data")
    }()

    func getCachedRegistrationData() -> RegistrationData? {
        guard let data = try? Data(contentsOf: cacheFile) else { return nil }
        let cachedData = (try? JSONDecoder().decode(RegistrationData.self, from: data))
        return cachedData
    }

    func save(registrationData: RegistrationData) throws {
        let data = try JSONEncoder().encode(registrationData)
        try data.write(to: cacheFile)
    }

    // TODO: Need to be cleared on log out
    func clearRegistrationData() {
        try? FileManager.default.removeItem(at: cacheFile)
    }
}
