import Foundation
import CountriesAPI
import PhoneNumberKit

extension CountriesAPI {

    func defaultRegionCode() -> String {
#if os(iOS) && !targetEnvironment(simulator) && !targetEnvironment(macCatalyst)
        let networkInfo = CTTelephonyNetworkInfo()
        let carrier: CTCarrier? = networkInfo.serviceSubscriberCellularProviders?.values.first(where: { $0.mobileNetworkCode != nil })
        if let isoCountryCode = carrier?.isoCountryCode {
            return isoCountryCode.lowercased()
        }
#endif
        return Locale.current.regionCode?.lowercased() ?? PhoneNumberKit.defaultRegionCode().lowercased()
    }

    func currentCountryName() async throws -> Country? {
        return try await self.fetchCountries().first { country in
            country.code == defaultRegionCode()
        }
    }
}
