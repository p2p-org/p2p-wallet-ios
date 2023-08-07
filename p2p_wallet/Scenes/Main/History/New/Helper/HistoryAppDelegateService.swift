import Foundation
import UIKit

class HistoryAppdelegateService: NSObject, AppDelegateService {
    static var shouldUpdateHistory = Notification(
        name: Notification.Name(rawValue: "HistoryAppdelegateServiceShouldUpdateHistory"),
        object: nil,
        userInfo: nil
    )

    func application(
        _: UIApplication,
        didReceiveRemoteNotification _: [AnyHashable: Any],
        fetchCompletionHandler _: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        NotificationCenter.default.post(Self.shouldUpdateHistory)
    }
}
