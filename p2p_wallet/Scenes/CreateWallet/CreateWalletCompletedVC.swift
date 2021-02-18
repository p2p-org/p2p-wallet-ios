//
//  CreateWalletCompletedVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 10/29/20.
//

import Foundation
import SwiftUI

class CreateWalletCompletedVC: WLIntroVC {
    // MARK: - Subviews
    lazy var nextButton = WLButton.stepButton(type: .blue, label: L10n.next.uppercaseFirst)
        .onTap(self, action: #selector(buttonNextDidTouch))
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        descriptionLabel.isHidden = false
        titleLabel.text = L10n.congratulations
        descriptionLabel.text = L10n.yourWalletHasBeenSuccessfullyCreated
        
        buttonsStackView.addArrangedSubviews([
            nextButton,
            UIView(height: 56)
        ])
    }
    
    // MARK: - Actions
    @objc func buttonNextDidTouch() {
        let vc = DependencyContainer.shared.makeSSPinCodeVC()
        UIApplication.shared.changeRootVC(to: vc, withNaviationController: true)
    }
}

@available(iOS 13, *)
struct WLCreateWalletCompleted_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewControllerPreview {
                CreateWalletCompletedVC()
            }
            .previewDevice("iPhone SE (2nd generation)")
        }
    }
}
