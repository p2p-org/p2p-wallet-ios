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
    
    override func bind() {
        super.bind()
        textView.rx.didEndEditing
            .subscribe(onNext: { [weak self] _ in
                self?.analyticsManager.log(event: .recoveryEnterSeedKeydown)
            })
            .disposed(by: disposeBag)
    }
    
    override func buttonPasteDidTouch() {
        analyticsManager.log(event: .recoveryEnterSeedPaste)
        super.buttonPasteDidTouch()
    }
    
    override func buttonNextDidTouch() {
        analyticsManager.log(event: .recoveryDoneClick)
        super.buttonNextDidTouch()
    }
}
