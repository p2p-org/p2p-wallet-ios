//
//  WLBottomSheet.swift
//  p2p_wallet
//
//  Created by Chung Tran on 11/12/20.
//

import Foundation

class WLBottomSheet: FlexibleHeightVC {
    init() {
        super.init(position: .bottom)
    }

    override func fittingHeightInContainer(frame: CGRect) -> CGFloat {
        let height = super.fittingHeightInContainer(frame: frame)
        return height + 30
    }

    override func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        let pc = super.presentationController(
            forPresented: presented,
            presenting: presenting,
            source: source
        ) as! PresentationController
        pc.roundedCorner = [.topLeft, .topRight]
        pc.cornerRadius = 25
        return pc
    }

    override func setUp() {
        super.setUp()

        if let child = build() {
            stackView.addArrangedSubview(child)
        }
    }

    func build() -> UIView? { nil }
}
