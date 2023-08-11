import CountriesAPI
import Foundation
import PhoneNumberKit

extension CountriesAPI {
    func defaultRegionCode() -> String {
        Locale.current.regionCode?.lowercased() ?? PhoneNumberKit.defaultRegionCode().lowercased()
    }

    func currentCountryName() async throws -> Region? {
        try await fetchRegions().first { country in
            country.alpha2.lowercased() == defaultRegionCode()
        }
    }
}
