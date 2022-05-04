//
//  NotificationService.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/12/2021.
//

import Foundation
import Resolver
import RxCocoa
import RxSwift
import UIKit

protocol NotificationService {
    typealias DeviceTokenResponse = JsonRpcResponseDto<DeviceTokenResponseDto>

    func sendRegisteredDeviceToken(_ deviceToken: Data) async
    func showInAppNotification(_ notification: InAppNotification)
    func wasAppLaunchedFromPush(launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
    func didReceivePush(userInfo: [AnyHashable: Any])
    func notificationWasOpened()

    var showNotification: Observable<NotificationType> { get }
    var showFromLaunch: Bool { get }
}

final class NotificationServiceImpl: NSObject, NotificationService {
    @Injected private var accountStorage: AccountStorageType
    @Injected private var notificationRepository: NotificationRepository

    private let deviceTokenKey = "deviceToken"
    private let openAfterPushKey = "openAfterPushKey"

    private let showNotificationRelay = PublishRelay<NotificationType>()
    var showNotification: Observable<NotificationType> { showNotificationRelay.asObservable() }
    var showFromLaunch: Bool { UserDefaults.standard.bool(forKey: openAfterPushKey) }

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        guard let deviceToken = UserDefaults.standard.data(forKey: deviceTokenKey) else { return }

        Task.detached(priority: .background) { [unowned self] in
            await sendRegisteredDeviceToken(deviceToken)
        }
    }

    func sendRegisteredDeviceToken(_ deviceToken: Data) async {
        guard let publicKey = accountStorage.account?.publicKey.base58EncodedString else { return }
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        UserDefaults.standard.set(deviceToken, forKey: deviceTokenKey)

        do {
            _ = try await notificationRepository.sendDeviceToken(model: .init(
                deviceToken: token,
                clientId: publicKey,
                deviceInfo: .init(
                    osName: UIDevice.current.systemName,
                    osVersion: UIDevice.current.systemVersion,
                    deviceModel: UIDevice.current.model
                )
            ))
            UserDefaults.standard.removeObject(forKey: deviceTokenKey)
        } catch {
            UserDefaults.standard.set(deviceToken, forKey: deviceTokenKey)
        }
    }

    func showInAppNotification(_ notification: InAppNotification) {
        UIApplication.shared.showToast(message: createTextFromNotification(notification))
    }

    func wasAppLaunchedFromPush(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if launchOptions?[.remoteNotification] != nil {
            UserDefaults.standard.set(true, forKey: openAfterPushKey)
        }
    }

    func didReceivePush(userInfo _: [AnyHashable: Any]) {
        showNotificationRelay.accept(.history)
    }

    func notificationWasOpened() {
        UserDefaults.standard.removeObject(forKey: openAfterPushKey)
    }

    private func createTextFromNotification(_ notification: InAppNotification) -> String {
        var array = [String]()
        if let emoji = notification.emoji {
            array.append(emoji)
        }
        array.append(notification.message)
        return array.joined(separator: " ")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationServiceImpl: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.alert, .sound, .badge])
    }
}

// MARK: - Show Toast

private extension UIApplication {
    func showToast(
        message: String?,
        backgroundColor: UIColor = .h2c2c2e,
        alpha: CGFloat = 0.8,
        shadowColor: UIColor = .h6d6d6d.onDarkMode(.black),
        completion: (() -> Void)? = nil
    ) {
        guard let message = message else { return }

        let toast = BERoundedCornerShadowView(
            shadowColor: shadowColor,
            radius: 16,
            offset: .init(width: 0, height: 8),
            opacity: 1,
            cornerRadius: 12,
            contentInset: .init(x: 20, y: 10)
        )
        toast.backgroundColor = backgroundColor
        toast.mainView.alpha = alpha

        let label = UILabel(text: message, textSize: 15, textColor: .white, numberOfLines: 0, textAlignment: .center)
        label.tag = 1

        toast.stackView.addArrangedSubview(label)
        toast.autoSetDimension(.width, toSize: 335, relation: .lessThanOrEqual)

        kWindow?.addSubview(toast)
        toast.autoAlignAxis(toSuperviewAxis: .vertical)
        toast.autoPinEdge(toSuperviewSafeArea: .top, withInset: -100)

        kWindow?.bringSubviewToFront(toast)
        kWindow?.layoutIfNeeded()
        toast.constraintToSuperviewWithAttribute(.top)?.constant = 25

        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.kWindow?.layoutIfNeeded()
        } completion: { _ in
            completion?()

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self, weak toast] in
                toast?.constraintToSuperviewWithAttribute(.top)?.constant = -100

                UIView.animate(withDuration: 0.3) { [weak self] in
                    self?.kWindow?.layoutIfNeeded()
                } completion: { [weak toast] _ in
                    toast?.removeFromSuperview()
                }
            }
        }
    }
}
