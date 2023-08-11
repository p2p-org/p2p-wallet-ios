import Foundation

/// Resend timer interval
let EnterSMSCodeCountdownLegs: [TimeInterval] = [30, 40, 60, 90, 120]

public struct ResendCounter: Codable, Equatable {
    public let attempt: Int
    public let until: Date

    public func incremented() -> ResendCounter {
        let newAttempt = attempt + 1
        return ResendCounter(
            attempt: newAttempt,
            until: Date().ceiled().addingTimeInterval(interval(for: newAttempt))
        )
    }

    private func interval(for attempt: Int) -> TimeInterval {
        let timeInterval = attempt >= EnterSMSCodeCountdownLegs.count
            ? EnterSMSCodeCountdownLegs[EnterSMSCodeCountdownLegs.count - 1]
            : EnterSMSCodeCountdownLegs[attempt]
        return timeInterval
    }

    public static func zero() -> Self {
        .init(attempt: 0, until: Date().ceiled().addingTimeInterval(EnterSMSCodeCountdownLegs[0]))
    }
}

private extension Date {
    func ceiled() -> Date {
        let date = ceil(Date().timeIntervalSince1970)
        return Date(timeIntervalSince1970: date)
    }
}
