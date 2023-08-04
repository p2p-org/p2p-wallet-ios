import Foundation

public protocol CountriesAPI {
    func fetchCountries() async throws -> Countries
    /// Fetches regions from the server
    func fetchRegions() async throws -> [Region]
}

public final class CountriesAPIImpl: CountriesAPI {
    public init() {}

    public func fetchCountries() async throws -> Countries {
        try await Task {
            let b: Bundle
            #if SWIFT_PACKAGE
            b = Bundle.module
            #else
            b = Bundle(for: Self.self)
            #endif
            // Country list source https://github.com/Sonatrix/country-list
            let url = b.url(forResource: "countries", withExtension: "json")!
            try Task.checkCancellation()
            let data = try Data(contentsOf: url)
            let countries = try JSONDecoder().decode(Countries.self, from: data)
            try Task.checkCancellation()
            return countries
        }.value
    }

    public func fetchRegions() async throws -> [Region] {
        let regionListURL = URL(string: "https://raw.githubusercontent.com/p2p-org/country-list/main/country-list.json")!
        let data = try Data(contentsOf: regionListURL)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([Region].self, from: data)
    }
}
