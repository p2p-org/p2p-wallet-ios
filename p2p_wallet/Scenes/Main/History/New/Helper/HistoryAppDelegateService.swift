import Combine
import Foundation

class HistoryAppdelegateService: NSObject, AppDelegateService {

    static var shouldUpdateHistory = Notification(name: Notification.Name(rawValue: "HistoryAppdelegateServiceShouldUpdateHistory"), object: nil, userInfo: nil)

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        NotificationCenter.default.post(Self.shouldUpdateHistory)
    }
}
