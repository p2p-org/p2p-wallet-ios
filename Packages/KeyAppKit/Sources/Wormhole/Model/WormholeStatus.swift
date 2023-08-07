import Foundation

public enum WormholeStatus: String, Codable, Hashable {
    case failed
    case pending
    case expired
    case canceled
    case inProgress = "in_progress"
    case completed
}
