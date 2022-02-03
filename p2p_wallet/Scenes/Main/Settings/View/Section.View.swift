//  Section.View.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 11.01.22.
//
//

import UIKit
import RxSwift
import RxCocoa

extension Settings {
    class SectionView: BECompositionView {
        let title: String?
        let children: [UIView]
        
        init(title: String? = nil, @BEViewBuilder builder: Builder) {
            self.title = title
            self.children = builder()
            super.init()
        }
        
        override func build() -> UIView {
            UIStackView(axis: .vertical, alignment: .fill) {
                if title != nil {
                    UILabel(text: title?.uppercased(), textSize: 12, textColor: .secondaryLabel)
                        .padding(.init(top: 0, left: 18, bottom: 8, right: 0))
                }
                UIStackView(axis: .vertical, alignment: .fill, arrangedSubviews: children)
                    .backgroundColor(color: .contentBackground)
                    .border(width: 1, color: .f2f2f7)
                    .box(cornerRadius: 12)
                    .lightShadow()
            }
        }
    }
}
