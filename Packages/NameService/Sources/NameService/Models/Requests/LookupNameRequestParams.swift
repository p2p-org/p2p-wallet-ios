struct LookupNameRequestParams: Codable {
    let owner: String
    let withTLD: Bool
    
    enum CodingKeys: String, CodingKey {
        case owner
        case withTLD = "with_tld"
    }
}
