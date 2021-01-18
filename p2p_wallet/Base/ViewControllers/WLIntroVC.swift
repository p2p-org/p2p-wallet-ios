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
    override var padding: UIEdgeInsets {
        .zero
    }
    
    // MARK: - Subviews
    lazy var p2pValidatorLogo = UIImageView.p2pValidatorLogo
    lazy var spacer1 = UIView.spacer
    lazy var titleLabel = UILabel(font: FontFamily.Montserrat.extraBold.font(size: 32), textColor: .white, textAlignment: .center)
    lazy var descriptionLabel = UILabel(textSize: 17, textColor: UIColor.white.withAlphaComponent(0.5), numberOfLines: 0, textAlignment: .center)
    lazy var spacer2 = UIView.spacer
    lazy var buttonsStackView = UIStackView(axis: .vertical, spacing: 16, alignment: .fill, distribution: .fill)
    
    override func setUp() {
        super.setUp()
        // static background color
        view.backgroundColor = .introBgStatic
        
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
            spacer2,
            BEStackViewSpacing(53),
            buttonsStackView
                .centeredHorizontallyView
        ])
        
        spacer1.heightAnchor.constraint(equalTo: spacer2.heightAnchor, multiplier: 2)
            .isActive = true
        buttonsStackView.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -60)
            .isActive = true
        
        scrollView.contentView.autoPinBottomToSuperViewSafeAreaAvoidKeyboard()
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
