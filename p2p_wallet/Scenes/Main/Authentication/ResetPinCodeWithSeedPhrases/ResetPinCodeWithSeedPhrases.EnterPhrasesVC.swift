//
//  ResetPinCodeWithSeedPhrases.EnterPhrasesVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 28/06/2021.
//

import BEPureLayout
import RxCocoa
import RxSwift
import UIKit

extension ResetPinCodeWithSeedPhrases {
    class EnterPhrasesVC: BEScene {
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        var completion: (([String]) -> Void)?
        let error = BehaviorRelay<Error?>(value: nil)
        var dismissAfterCompletion = true

        override func build() -> UIView {
            BEVStack {
                BEHStack(distribution: .equalCentering) {
                    UIButton.text(text: L10n.back, fontSize: 17, weight: .regular, tintColor: .h5887ff)

                    UILabel(text: L10n.resettingYourPIN, textSize: 17, weight: .semibold, textAlignment: .center)

                    UIButton.text(text: L10n.done, fontSize: 17, weight: .semibold, tintColor: .h5887ff)
                }
                .backgroundColor(color: .fafafa)
                .frame(height: 58)

                // Input
                BEHStack {
                    ExpandableTextView()
                        .setupWithType(ExpandableTextView.self) { textField in
                            textField.placeholder = L10n.yourSecurityKey
                        }
                        .withTag(1)
                    UIButton(
                        label: L10n.paste,
                        labelFont: .systemFont(ofSize: 17, weight: .medium),
                        textColor: .h5887ff
                    )
                    .frame(width: 78)
                    .withTag(2)
                }
                .setup { view in
                    guard
                        let v1 = view.viewWithTag(1),
                        let v2 = view.viewWithTag(2)
                    else { return }

                    v2.autoMatch(.height, to: .height, of: v1)
                }
                .padding(.init(top: 18, left: 18, bottom: 0, right: 18))

                // Separator
                UIView
                    .separator(height: 1, color: .separator)
                    .padding(.init(x: 18, y: 0))
                
                UIView.spacer
            }
        }
    }
}
