import Foundation

public struct Response<T: Codable & Equatable>: Codable, Equatable {
    public let data: T?
    public let timeTaken: Double?
    public let contextSlot: Int?

    public let message: String?

    public init(data: T, timeTaken: Double, contextSlot: Int?, message: String?) {
        self.data = data
        self.timeTaken = timeTaken
        self.contextSlot = contextSlot
        self.message = message
    }
}
