import AnalyticsManager
import BEPureLayout
import Combine
import Foundation
import KeyAppUI
import Resolver
import UIKit

protocol NotificationService {
    func sendRegisteredDeviceToken(_ deviceToken: Data, ethAddress: String?) async throws
    func deleteDeviceToken(ethAddress: String?) async throws
    func showInAppNotification(_ notification: InAppNotification)
    func showToast(title: String?, text: String?)
    func showToast(title: String?, text: String?, withAutoHidden: Bool)
    func showToast(title: String?, text: String?, haptic: Bool)
    func showAlert(title: String, text: String)
    func hideToasts()
    func showDefaultErrorNotification()
    func showConnectionErrorNotification()
    func wasAppLaunchedFromPush(launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
    func didReceivePush(userInfo: [AnyHashable: Any])
    func notificationWasOpened()
    func unregisterForRemoteNotifications()
    func registerForRemoteNotifications()
    func requestRemoteNotificationPermission()

    var showNotification: AnyPublisher<NotificationType, Never> { get }
    var showFromLaunch: Bool { get }
}

final class NotificationServiceImpl: NSObject, NotificationService {
    @Injected private var analyticsManager: AnalyticsManager
    @Injected private var accountStorage: AccountStorageType
    @Injected private var notificationRepository: NotificationRepository

    private let deviceTokenKey = "deviceToken"
    private let openAfterPushKey = "openAfterPushKey"

    private let showNotificationRelay = PassthroughSubject<NotificationType, Never>()
    var showNotification: AnyPublisher<NotificationType, Never> { showNotificationRelay.receive(on: DispatchQueue.main).eraseToAnyPublisher() }
    var showFromLaunch: Bool { UserDefaults.standard.bool(forKey: openAfterPushKey) }

    override init() {
        super.init()

        UNUserNotificationCenter.current().delegate = self
    }

    func unregisterForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.unregisterForRemoteNotifications()
        }
    }

    func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func requestRemoteNotificationPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
                Defaults.didSetEnableNotifications = granted
                self?.analyticsManager.log(parameter: .pushAllowed(granted))
            }
    }

    func sendRegisteredDeviceToken(_ deviceToken: Data, ethAddress: String? = nil) async throws {
        guard let publicKey = accountStorage.account?.publicKey.base58EncodedString else { return }
        let token = deviceToken.formattedDeviceToken

        let result = try await notificationRepository.sendDeviceToken(model: .init(
            deviceToken: token,
            clientId: publicKey,
            ethPubkey: ethAddress,
            deviceInfo: .init(
                osName: UIDevice.current.systemName,
                osVersion: UIDevice.current.systemVersion,
                deviceModel: UIDevice.current.model
            )
        ))

        print(result)

        Defaults.lastDeviceToken = deviceToken
    }

    func deleteDeviceToken(ethAddress: String? = nil) async throws {
        guard
            let token = Defaults.lastDeviceToken?.formattedDeviceToken,
            let publicKey = accountStorage.account?.publicKey.base58EncodedString
        else { return }
        _ = try await notificationRepository.removeDeviceToken(model: .init(
            deviceToken: token,
            clientId: publicKey,
            ethPubkey: ethAddress
        ))

        Defaults.lastDeviceToken = nil
    }

    func showInAppNotification(_ notification: InAppNotification) {
        DispatchQueue.main.async {
            SnackBar(title: notification.emoji, text: notification.message)
                .showInKeyWindow()
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    func showToast(title: String?, text: String?) {
        DispatchQueue.main.async {
            SnackBar(
                title: title ?? "😓",
                text: text ?? L10n.SomethingWentWrong.pleaseTryAgain
            )
            .showInKeyWindow()
        }
    }

    func showToast(title: String? = nil, text: String? = nil, withAutoHidden: Bool) {
        DispatchQueue.main.async {
            SnackBar(
                title: title ?? "😓",
                text: text ?? L10n.SomethingWentWrong.pleaseTryAgain
            )
            .showInKeyWindow(autoHide: withAutoHidden)
        }
    }

    func showToast(title: String?, text: String?, haptic: Bool) {
        showToast(title: title, text: text)
        if haptic {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    func showAlert(title: String, text: String) {
        DispatchQueue.main.async {
            UIApplication.shared.keyWindow?.topViewController()?
                .showAlert(title: title, message: text)
        }
    }

    func hideToasts() {
        SnackBarManager.shared.dismissAll()
    }

    func showDefaultErrorNotification() {
        DispatchQueue.main.async {
            SnackBar(
                title: "😓",
                text: L10n.SomethingWentWrong.pleaseTryAgain
            )
            .showInKeyWindow()
        }
    }

    func showConnectionErrorNotification() {
        showToast(title: "🥺", text: L10n.youHaveNoInternetConnection)
    }

    func wasAppLaunchedFromPush(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if launchOptions?[.remoteNotification] != nil {
            analyticsManager.log(event: .appOpened(sourceOpen: "Push"))
            UserDefaults.standard.set(true, forKey: openAfterPushKey)
        } else {
            analyticsManager.log(event: .appOpened(sourceOpen: "Direct"))
        }
    }

    func didReceivePush(userInfo _: [AnyHashable: Any]) {
        showNotificationRelay.send(.history)
    }

    func notificationWasOpened() {
        UserDefaults.standard.removeObject(forKey: openAfterPushKey)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationServiceImpl: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.list, .banner, .sound, .badge])
    }
}

// MARK: - Helpers

private extension SnackBar {
    func showInKeyWindow(autoHide: Bool = true) {
        guard let window = UIApplication.shared.keyWindow else { return }
        show(in: window, autoHide: autoHide)
    }
}

private extension Data {
    var formattedDeviceToken: String {
        let tokenParts = map { data in String(format: "%02.2hhx", data) }
        return tokenParts.joined()
    }
}

private extension UIWindow {
    func topViewController() -> UIViewController? {
        rootViewController?.topMostViewController()
    }
}

private extension UIViewController {
    func topMostViewController() -> UIViewController? {
        if presentedViewController == nil { return self }

        if let navigation = presentedViewController as? UINavigationController {
            return navigation.visibleViewController!.topMostViewController() ?? self
        }

        if let tab = presentedViewController as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.topMostViewController() ?? self
            }
            return tab.topMostViewController() ?? self
        }

        return presentedViewController!.topMostViewController() ?? self
    }
}
