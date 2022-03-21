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

    private let autoHide: Bool = true
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
            if autoHide { UIView.animate(withDuration: 0.3) { self.isHidden = false } }
        case .error:
            backgroundColor = .alert
            UIView.animate(withDuration: 0.3) { self.isHidden = false }
            if autoHide {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    UIView.animate(withDuration: 0.3) { self.isHidden = true }
                }
            }
        case .success:
            backgroundColor = .attentionGreen
            if autoHide {
                UIView.animate(withDuration: 0.3) { self.isHidden = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    UIView.animate(withDuration: 0.3) { self.isHidden = true }
                }
            }
        }

        label.text = text
    }
}
