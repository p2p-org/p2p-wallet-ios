//
//  WLOverviewView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 23/12/2020.
//

import Foundation
import UIKit

class WLOverviewView: WLFloatingPanelView {
    override func commonInit() {
        super.commonInit()
        stackView.spacing = 0
        backgroundColor = .none

        let buttonsView = createButtonsView()
        stackView.addArrangedSubviews {
            createTopView()
            buttonsView
        }

        buttonsView.autoMatch(.height, to: .height, of: self, withMultiplier: 1.0, relation: .lessThanOrEqual)
    }

    func createTopView() -> UIView {
        fatalError("Must override")
    }

    func createButtonsView() -> UIView {
        fatalError("Must override")
    }
}
