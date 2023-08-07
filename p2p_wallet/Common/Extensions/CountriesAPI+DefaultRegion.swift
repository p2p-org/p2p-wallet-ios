import CountriesAPI
import Foundation
import PhoneNumberKit

extension CountriesAPI {
    func defaultRegionCode() -> String {
        Locale.current.regionCode?.lowercased() ?? PhoneNumberKit.defaultRegionCode().lowercased()
    }

    func currentCountryName() async throws -> Country? {
        try await fetchCountries().first { country in
            country.code == defaultRegionCode()
        }
    }
}
