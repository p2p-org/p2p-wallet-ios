//
//  RecoveryEnterSeedsViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/06/2021.
//

import Foundation

class RecoveryEnterSeedsViewController: WLEnterPhrasesVC {
    // MARK: - Dependencies
    private let analyticsManager: AnalyticsManagerType
    
    // MARK: - Initializers
    init(handler: PhrasesCreationHandler, analyticsManager: AnalyticsManagerType) {
        self.analyticsManager = analyticsManager
        super.init(handler: handler)
    }
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        analyticsManager.log(event: .recoveryEnterSeedOpen)
    }
    
    override func setUp() {
        super.setUp()
        var index = 0
        stackView.insertArrangedSubviews(at: &index) {
            UIStackView(axis: .horizontal, spacing: 16, alignment: .fill, distribution: .fill, arrangedSubviews: [
                UIImageView(width: 24, height: 24, image: .securityKey, tintColor: .white),
                UILabel(text: L10n.securityKey.uppercaseFirst, textSize: 21, weight: .semibold)
            ])
                .padding(.init(all: 20))
            UIView.separator(height: 1, color: .separator)
        }
    }
    
    override func buttonPasteDidTouch() {
        analyticsManager.log(event: .recoveryEnterSeedPaste)
        super.buttonPasteDidTouch()
    }
    
    override func buttonNextDidTouch() {
        analyticsManager.log(event: .recoveryDoneClick)
        super.buttonNextDidTouch()
    }
    
    override func wlPhrasesTextViewDidBeginEditing(_ textView: WLPhrasesTextView) {
        analyticsManager.log(event: .recoveryEnterSeedKeydown)
        super.wlPhrasesTextViewDidBeginEditing(textView)
    }
}
