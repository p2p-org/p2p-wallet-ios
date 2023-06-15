import XCTest
@testable import Deeplinking

class URLParserTests: XCTestCase {
    
    func testParseURIScheme_LoginWithURL() throws {
        // Arrange
        let urlString = "keyapptest://onboarding/seedPhrase?value=seed-phrase-separated-by-hyphens&pincode=222222"
        let url = try XCTUnwrap(URL(string: urlString))
        let parser = try URLParser(url: url)
        
        // Act
        let route = try parser.parseURIScheme()
        
        // Assert
        if case .debugLoginWithURL(let seedPhrase, let pincode) = route {
            XCTAssertEqual(seedPhrase, "seed-phrase-separated-by-hyphens")
            XCTAssertEqual(pincode, "222222")
        } else {
            XCTFail("Unexpected route type")
        }
    }
    
    func testParseURIScheme_ClaimSentViaLink() throws {
        // Arrange
        let urlString = "keyapp://t/my-seed"
        let url = try XCTUnwrap(URL(string: urlString))
        let parser = try URLParser(url: url)
        
        // Act
        let route = try parser.parseURIScheme()
        
        // Assert
        if case .claimSentViaLink(let seed) = route {
            XCTAssertEqual(seed, "my-seed")
        } else {
            XCTFail("Unexpected route type")
        }
    }
    
    func testParseURIScheme_UnsupportedURL() throws {
        // Arrange
        let urlString = "unsupported://url"
        let url = try XCTUnwrap(URL(string: urlString))
        let parser = try URLParser(url: url)
        
        // Act & Assert
        XCTAssertThrowsError(try parser.parseURIScheme()) { error in
            XCTAssertEqual(error as? DeeplinkingError, DeeplinkingError.unsupportedURL(url))
        }
    }
    
    func testParseUniversalLink_IntercomSurvey() throws {
        // Arrange
        let urlString = "https://key.app/intercom?intercom_survey_id=133423424"
        let url = try XCTUnwrap(URL(string: urlString))
        let parser = try URLParser(url: url)
        
        // Act
        let route = try parser.parseUniversalLink(from: url)
        
        // Assert
        if case .intercomSurvey(let id) = route {
            XCTAssertEqual(id, "133423424")
        } else {
            XCTFail("Unexpected route type")
        }
    }
    
    func testParseUniversalLink_ClaimSentViaLink() throws {
        // Arrange
        let urlString = "https://t.key.app/my-seed"
        let url = try XCTUnwrap(URL(string: urlString))
        let parser = try URLParser(url: url)
        
        // Act
        let route = try parser.parseUniversalLink(from: url)
        
        // Assert
        if case .claimSentViaLink(let seed) = route {
            XCTAssertEqual(seed, "/my-seed")
        } else {
            XCTFail("Unexpected route type")
        }
    }
    
    func testParseUniversalLink_UnsupportedURL() throws {
        // Arrange
        let urlString = "http://example.com"
        let url = try XCTUnwrap(URL(string: urlString))
        let parser = try URLParser(url: url)
        
        // Act & Assert
        XCTAssertThrowsError(try parser.parseUniversalLink(from: url)) { error in
            XCTAssertEqual(error as? DeeplinkingError, DeeplinkingError.unsupportedURL(url))
        }
    }
}
