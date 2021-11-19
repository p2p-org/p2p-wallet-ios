//
//  WLStatusIndicatorView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 18/11/2021.
//

import Foundation
import UIKit

class WLStatusIndicatorView: BEView {
    enum State {
        case loading, error, success
    }
    
    private let label = UILabel(text: "loading...", textSize: 12, weight: .semibold, textColor: .white, numberOfLines: 0, textAlignment: .center)
    
    override func commonInit() {
        super.commonInit()
        addSubview(label)
        label.autoPinEdgesToSuperviewEdges(with: .init(x: 18, y: 8))
    }
    
    func setUp(state: State, text: String?) {
        switch state {
        case .loading:
            backgroundColor = .ff9500
        case .error:
            backgroundColor = .alert
        case .success:
            backgroundColor = .attentionGreen
        }
        
        label.text = text
    }
}
