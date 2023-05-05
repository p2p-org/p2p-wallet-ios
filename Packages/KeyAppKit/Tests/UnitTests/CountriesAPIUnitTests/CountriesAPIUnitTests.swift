import Foundation
import XCTest
import CountriesAPI

class CountriesAPIUnitTests: XCTestCase {
    let countriesAPI = CountriesAPIImpl()
    
    func testGetCountryByName() async throws {
        let countries = try await countriesAPI.fetchCountries()
        let vn = countries.first(where: {$0.name == "Vietnam"})
        XCTAssertEqual(vn?.dialCode, "+84")
        
        let ru = countries.first(where: {$0.name == "United States"})
        XCTAssertEqual(ru?.dialCode, "+1")
    }
    
    func testGetCountryByEmoji() async throws {
        let countries = try await countriesAPI.fetchCountries()
        let vn = countries.first(where: {$0.emoji == "🇻🇳"})
        XCTAssertEqual(vn?.dialCode, "+84")
        
        let ru = countries.first(where: {$0.emoji == "🇺🇸"})
        XCTAssertEqual(ru?.dialCode, "+1")
    }
}
