import Foundation
import CountriesAPI
import PhoneNumberKit

extension CountriesAPI {

    func defaultRegionCode() -> String {
        return Locale.current.regionCode?.lowercased() ?? PhoneNumberKit.defaultRegionCode().lowercased()
    }

    func currentCountryName() async throws -> Country? {
        return try await self.fetchCountries().first { country in
            country.code == defaultRegionCode()
        }
    }
}
