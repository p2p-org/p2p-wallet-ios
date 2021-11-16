//
//  RecoveryEnterSeedsViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/06/2021.
//

import Foundation

class RecoveryEnterSeedsViewController: WLEnterPhrasesVC {
    // MARK: - Dependencies
    @Injected private var analyticsManager: AnalyticsManagerType
    
    // MARK: - Subviews
    lazy var navigationBar: WLNavigationBar = {
        let navigationBar = WLNavigationBar(forAutoLayout: ())
        navigationBar.titleLabel.text = L10n.securityKey
        navigationBar.backButton.onTap(self, action: #selector(back))
        return navigationBar
    }()
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        analyticsManager.log(event: .recoveryEnterSeedOpen)
    }
    
    override func setUp() {
        super.setUp()
        
        view.addSubview(navigationBar)
        navigationBar.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
        
        scrollView.constraintToSuperviewWithAttribute(.top)?.isActive = false
        scrollView.autoPinEdge(.top, to: .bottom, of: navigationBar)
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
