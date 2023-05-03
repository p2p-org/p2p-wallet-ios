struct NameInfo: Codable {
    public let parent: String
    public let ownerClass: String
    public let name: String?
    public let address: String
    public let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case parent, address, name
        case ownerClass = "class"
        case updatedAt = "updated_at"
    }
}
