//
//  WLIntroVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/01/2021.
//

import Foundation
import SwiftUI

class WLIntroVC: BaseVStackVC {
    // MARK: - Settings
    override var preferredNavigationBarStype: BEViewController.NavigationBarStyle {
        .hidden
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    override var padding: UIEdgeInsets {
        UIEdgeInsets(x: 30, y: 0)
    }
    
    // MARK: - Subviews
    lazy var backButton: UIButton = {
        let button = UIButton(width: 32, height: 32)
        button.setImage(.backButtonDark, for: .normal)
        button.onTap(self, action: #selector(back))
        return button
    }()
    lazy var p2pValidatorLogo = UIImageView.p2pValidatorLogo
    lazy var spacer1 = UIView.spacer
    lazy var titleLabel = UILabel(font: FontFamily.Montserrat.extraBold.font(size: 32), textColor: .white, textAlignment: .center)
    lazy var descriptionLabel = UILabel(textSize: 17, textColor: UIColor.white.withAlphaComponent(0.5), numberOfLines: 0, textAlignment: .center)
    lazy var buttonsStackView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill)
    
    override func setUp() {
        super.setUp()
        // static background color
        view.backgroundColor = .introBgStatic
        
        // Custom back button
        view.addSubview(backButton)
        backButton.autoPinEdge(toSuperviewSafeArea: .leading, withInset: 20)
        backButton.autoPinEdge(toSuperviewSafeArea: .top, withInset: 20)
        backButton.isHidden = true
        
        // lines view
        let linesView = UIImageView(image: .introLinesBg)
        view.insertSubview(linesView, at: 0)
        linesView.autoPinEdgesToSuperviewEdges()
        
        stackView.addArrangedSubviews([
            UIView.spacer(46),
            p2pValidatorLogo
                .centeredHorizontallyView,
            spacer1,
            titleLabel,
            descriptionLabel,
            BEStackViewSpacing(53),
            buttonsStackView
        ])
        
        scrollView.contentView.autoPinBottomToSuperViewSafeAreaAvoidKeyboard(inset: 16)
    }
}

@available(iOS 13, *)
struct WLIntroVC_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewControllerPreview {
                WLIntroVC()
            }
            .previewDevice("iPhone SE (2nd generation)")
        }
    }
}
