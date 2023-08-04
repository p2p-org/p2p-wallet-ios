import Foundation
import CountriesAPI
import PhoneNumberKit

extension CountriesAPI {

    func defaultRegionCode() -> String {
        return Locale.current.regionCode?.lowercased() ?? PhoneNumberKit.defaultRegionCode().lowercased()
    }

    func currentCountryName() async throws -> Region? {
        return try await self.fetchRegions().first { country in
            country.alpha2.lowercased() == defaultRegionCode()
        }
    }
}
