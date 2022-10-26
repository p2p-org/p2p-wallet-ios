//
// Created by Giang Long Tran on 18.02.2022.
//

import Foundation

class FeedbackBanner: Banners.Banner {
    fileprivate static let id = "feedback-banner"

    init() {
        super.init(
            id: FeedbackBanner.id,
            priority: .medium,
            onTapAction: Banners.Actions.OpenScreen(screen: "feedback")
        )
    }

    override func getInfo() -> [InfoKey: Any] {
        [
            .title: L10n.suggestWaysToImproveKeyApp,
            .action: L10n.leaveFeedback,
            .background: UIColor(red: 0.843, green: 0.819, blue: 1, alpha: 1),
            .icon: UIImage.bannerFeedback,
        ]
    }
}

class FeedbackBannerHandler: Banners.Handler {
    weak var delegate: Banners.Service?

    func onRegister(with service: Banners.Service) {
        delegate = service
        delegate?.update(banner: FeedbackBanner())
    }
}
