//
//  ProfileVCBase.swift
//  p2p_wallet
//
//  Created by Chung Tran on 15/12/2020.
//

import Foundation

class ProfileVCBase: WLCenterSheet {
    override var padding: UIEdgeInsets {.init(all: 20)}
    var dataDidChange: Bool {false}
    lazy var doneButton = UIButton(label: L10n.done, labelFont: .systemFont(ofSize: 17), textColor: .textSecondary)
        .onTap(self, action: #selector(buttonDoneDidTouch))
    
    override func setUp() {
        super.setUp()
        stackView.addArrangedSubview(createHeaderView())
    }
    
    func createHeaderView() -> UIStackView {
        UIView.row([
            UIView.row([
                UIImageView(width: 4.5, height: 9, image: .backArrow, tintColor: .textBlack),
                UILabel(text: L10n.back, textSize: 17, textColor: .textSecondary)
            ])
                .with(spacing: 8)
                .onTap(self, action: #selector(back)),
            UILabel(text: title, textSize: 17, weight: .bold),
            doneButton
        ]).with(alignment: .fill, distribution: .equalCentering)
    }
    
    override func back() {
        if dataDidChange {
            showAlert(title: L10n.leaveThisPage, message: L10n.youHaveUnsavedChangesThatWillBeLostIfYouDecideToLeave, buttonTitles: [L10n.stay, L10n.leave], highlightedButtonIndex: 0) { (index) in
                if index == 1 {
                    super.back()
                }
            }
        } else {
            super.back()
        }
    }
    
    @objc func buttonDoneDidTouch() {
        if dataDidChange {saveChange()}
    }
    
    func saveChange() {
        
    }
}
