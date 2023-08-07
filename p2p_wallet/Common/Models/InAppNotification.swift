import Foundation

struct InAppNotification {
    let emoji: String?
    let message: String

    static func error(_ error: Error) -> Self {
        .init(emoji: "❌", message: error.readableDescription)
    }

    static func error(_ message: String) -> Self {
        .init(emoji: "❌", message: message)
    }

    static func done(_ message: String) -> Self {
        .init(emoji: "✅", message: message)
    }

    static func custom(_ emoji: String, _ message: String) -> Self {
        .init(emoji: emoji, message: message)
    }

    static func message(_ message: String) -> Self {
        .init(emoji: nil, message: message)
    }
}
