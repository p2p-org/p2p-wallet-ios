//
//  WLCenterSheet.swift
//  p2p_wallet
//
//  Created by Chung Tran on 27/11/2020.
//

import Foundation

class WLCenterSheet: FlexibleHeightVC {
    override var margin: UIEdgeInsets {.init(all: 16)}
    
    init() {
        super.init(position: .center)
    }
    
    override func fittingHeightInContainer(frame: CGRect) -> CGFloat {
        super.fittingHeightInContainer(frame: frame)
            - 32 // unknown why
    }
    
    override func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let pc = super.presentationController(forPresented: presented, presenting: presenting, source: source) as! PresentationController
        pc.roundedCorner = .allCorners
        pc.cornerRadius = 16
        return pc
    }
}
