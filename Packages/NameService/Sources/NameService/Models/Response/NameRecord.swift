public struct NameRecord: Codable {
    public let name: String?
    public let parent: String
    public let owner: String
    public let ownerClass: String
    
    public init(name: String?, parent: String, owner: String, ownerClass: String) {
        self.name = name
        self.parent = parent
        self.owner = owner
        self.ownerClass = ownerClass
    }
    
    enum CodingKeys: String, CodingKey {
        case parent
        case owner
        case ownerClass = "class"
        case name
    }
}
