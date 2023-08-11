import SwiftyUserDefaults

struct HomeBannerVisibility: DefaultsSerializable, Codable {
    let id: String
    let closed: Bool
}
