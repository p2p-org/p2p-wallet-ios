//
//  WelcomeViewController.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/30/20.
//

import Foundation
import SwiftUI

class WelcomeViewController: BaseVC {
    // MARK: - Dependencies
    private let viewModel: RootViewModelType = Resolver.resolve()
    private let name: String?
    private let isReturned: Bool
    
    init(isReturned: Bool, name: String?) {
        self.isReturned = isReturned
        self.name = name
        super.init()
    }
    
    override func setUp() {
        super.setUp()
        
        // pattern background view
        let patternView = UIView.introPatternView()
        view.addSubview(patternView)
        patternView.autoPinEdgesToSuperviewEdges()
        
        // stackview
        let title: String
        if isReturned {
            title = name == nil ? L10n.welcomeBack: L10n.welcomeBack(name!) + "!"
        } else {
            title = name == nil ? L10n.welcomeToP2PFamily: L10n.welcomeToP2PFamily(name!) + "!"
        }
        
        let stackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill) {
            UIView.ilustrationView(
                image: .introWelcomeToP2pFamily,
                title: title,
                description: L10n.YourP2PWalletIsFullySetUp.getReadyToExploreTheCryptoWorld
            )
                .padding(.init(x: 20, y: 0))
            WLStepButton.main(
                image: .lightningButton,
                text: L10n.startUsingP2PWallet
            )
                .onTap(self, action: #selector(finishSetup))
                .padding(.init(x: 20, y: 0))
        }
        view.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
        stackView.autoPinEdge(toSuperviewSafeArea: .bottom, withInset: 20)
    }
    
    @objc func finishSetup() {
        viewModel.finishSetup()
    }
}
