//
//  SolanaBuyToken.Scene.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 15.12.21.
//
//

import Foundation

extension SolanaBuyToken {
    class Scene: BEScene {
        @BENavigationBinding private var viewModel: SolanaBuyTokenSceneModel!
        
        override var preferredNavigationBarStype: NavigationBarStyle { .hidden }
        
        override init() {
            super.init()
        }
        
        override func build() -> UIView {
            BESafeArea {
                UIStackView(axis: .vertical, alignment: .fill) {
                    NewWLNavigationBar(title: "\(L10n.buy) Solana")
                        .onBack { [unowned self] in
                            print("back")
                            self.back()
                        }
                    UIView.spacer
                }
            }
        }
        
        override func layout() {
            var v: UIViewController? = parent
            while (v != nil) {
                if let v = v as? TabBarVC {
                    v.tabBar.isHidden = true
                }
                v = v?.parent
            }
        }
    }
}
