//
// Created by Giang Long Tran on 18.02.2022.
//

import Foundation
import RxSwift

class NotificationBanner: Banners.Banner {
    static fileprivate let id = "notification-banner"

    init() {
        super.init(
            id: NotificationBanner.id,
            priority: .low,
            onTap: Banners.OpenScreenAction(screen: "settings/notification")
        )
    }

    override func getInfo() -> [InfoKey: Any] {
        [
            .title: L10n.donTMissOutOnImportantUpdates,
            .action: L10n.turnOnNotifications,
            .background: UIColor(red: 0.957, green: 0.831, blue: 0.898, alpha: 1),
            .icon: UIImage.bannerNotification
        ]
    }
}

class NotificationBannerHandler: Banners.Handler {
    weak var delegate: Banners.Service?

    func onRegister(with service: Banners.Service) {
        delegate = service
        delegate?.update(banner: NotificationBanner())
    }
}
