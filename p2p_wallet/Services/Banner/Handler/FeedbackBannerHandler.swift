//
// Created by Giang Long Tran on 18.02.2022.
//

import Foundation
import RxSwift

class FeedbackBanner: Banners.Banner {
    static fileprivate let id = "feedback-banner"
    
    init() {
        super.init(
            id: FeedbackBanner.id,
            priority: .medium,
            onTap: Banners.OpenScreenAction(screen: "feedback")
        )
    }
    
    override func getInfo() -> [InfoKey: Any] {
        [
            .title: L10n.suggestWaysToImproveP2PWallet,
            .action: L10n.leaveFeedback,
            .background: UIColor(red: 0.843, green: 0.819, blue: 1, alpha: 1),
            .icon: UIImage.bannerFeedback
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