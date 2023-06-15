import Foundation

/// Object that is used for parse a link
final class URLParser {

    // MARK: - Properties

    private let url: URL
    private let components: URLComponents

    // MARK: - Initializer

    init(url: URL) throws {
        // assert url components
        guard let components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: true
        ) else {
            throw DeeplinkingError.unsupportedURL(url)
        }
        
        self.url = url
        self.components = components
    }

    // MARK: - Methods

    /// Detect route from a given link
    func parseURIScheme() throws -> Route {
        // get params
        let host = components.host
        let path = components.path
        let scheme = components.scheme
        
        // Login to test with urischeme
        // keyapptest://onboarding/seedPhrase?value=seed-phrase-separated-by-hyphens&pincode=222222
        if scheme == "keyapptest",
           host == "onboarding",
           path == "/seedPhrase",
           let params = components.queryItems,
           let seedPhrase: String = params.first(where: { $0.name == "value" })?.value,
           let pincode: String = params.first(where: { $0.name == "pincode" })?.value
        {
            return .debugLoginWithURL(seedPhrase: seedPhrase, pincode: pincode)
        }
        
        // Send via link
        // keyapp://t/<seed>
        else if scheme == "keyapp",
                host == "t",
                // fix url from URIScheme to Universal links
                let fixedURL = urlFromSeed(String(path.dropFirst()))
        {
            return .claimSentViaLink(url: fixedURL)
        }
        
        // Unsupported type
        throw DeeplinkingError.unsupportedURL(url)
    }
    
    func parseUniversalLink(from url: URL) throws -> Route {
        // Universal link must start with https
        guard components.scheme == "https" else {
            throw DeeplinkingError.unsupportedURL(url)
        }
        
        // Intercom survey
        // https://key.app/intercom?intercom_survey_id=133423424
        if components.host == "key.app",
           components.path == "/intercom",
           let queryItem = components.queryItems?.first(where: { $0.name == "intercom_survey_id" }),
           let value = queryItem.value
        {
            return .intercomSurvey(id: value)
        }
        
        // Send via link
        // https://t.key.app/<seed>
        else if components.host == "t.key.app" {
            return .claimSentViaLink(url: url)
        }
        
        // Unsupported type
        throw DeeplinkingError.unsupportedURL(url)
    }
}

// MARK: - Helpers

private func urlFromSeed(_ seed: String?) -> URL? {
    guard let seed else { return nil }
    var urlComponent = URLComponents()
    urlComponent.scheme = "https"
    urlComponent.host = "t.key.app"
    urlComponent.path = "/\(seed)"
    return urlComponent.url
}
