import Foundation

public protocol CountriesAPI {
    func fetchCountries() async throws -> Countries
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
}
